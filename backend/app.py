from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
from io import BytesIO
import spacy
from PyPDF2 import PdfReader
from docx import Document
import re
import logging
from datetime import datetime
import uuid
import os
import json
from typing import Dict, List, Any, Optional, Tuple

# Import improved utility classes
from utils.text_analyzer import TextAnalyzer
from utils.gemini_handler import GeminiHandler
from utils.file_processor import FileProcessor

# Flask app
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})  # Allow all origins in development

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# In-memory storage for results (replace with database in production)
results_store = {}

# Configuration constants
ALLOWED_EXTENSIONS = {'pdf', 'docx'}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB
KEYWORD_LIMIT = 15

# Initialize utility classes
try:
    text_analyzer = TextAnalyzer()
    file_processor = FileProcessor()
    gemini_handler = None
    if os.getenv('GOOGLE_API_KEY'):
        gemini_handler = GeminiHandler()
        logger.info("Gemini API initialized successfully")
    else:
        logger.warning("GOOGLE_API_KEY not set, Gemini features will be disabled")
except Exception as e:
    logger.error(f"Failed to initialize utilities: {e}")
    raise

def analyze_cv(text: str, job_description: Optional[str] = None, language: str = 'en') -> Dict[str, Any]:
    """
    Analyze CV text and compare with job description if provided.
    
    Args:
        text: Extracted text from CV
        job_description: Optional job description text
        language: Language of the CV ('en' or 'ar')
    
    Returns:
        Dictionary containing analysis results
    """
    try:
        # Generate a unique ID for this analysis
        analysis_id = str(uuid.uuid4())
        
        # Extract keywords using TextAnalyzer
        keywords = text_analyzer.extract_keywords(text)
        unique_keywords = list(set(keywords))
        
        # Calculate base score
        score = min(len(unique_keywords) * 2, 100)
        top_keywords = unique_keywords[:3] if len(unique_keywords) >= 3 else unique_keywords
        
        # Determine text direction based on language
        direction = "rtl" if language == 'ar' else "ltr"
        
        # Initialize analysis result
        analysis = {
            "id": analysis_id,
            "score": score,
            "keywords": unique_keywords[:KEYWORD_LIMIT],
            "summary": _get_localized_summary(top_keywords, len(unique_keywords), language),
            "analysis_date": datetime.now().isoformat(),
            "skills_comparison": {
                "matching_keywords": [],
                "missing_keywords": [],
                "match_percentage": 0
            },
            "searchability_issues": [],
            "education_comparison": [],
            "experience_comparison": [],
            "job_description": "",
            "recommendations": [],
            "language": language,
            "direction": direction,
            "score_breakdown": {
                "keyword_score": score,
                "match_score": 0,
                "format_score": _calculate_format_score(text, language)
            }
        }
        
        # If job description is provided, perform comparison
        if job_description:
            # Store the job description
            analysis["job_description"] = job_description
            
            # Use TextAnalyzer for detailed comparison
            comparison_result = text_analyzer.analyze_text(text, job_description)
            
            if comparison_result.get("success", False):
                # Update skills comparison
                analysis["skills_comparison"] = {
                    "matching_keywords": comparison_result.get("skills_comparison", {}).get("matching_keywords", []),
                    "missing_keywords": comparison_result.get("skills_comparison", {}).get("missing_keywords", []),
                    "match_percentage": comparison_result.get("skills_comparison", {}).get("match_percentage", 0)
                }
                
                # Update score based on match percentage
                match_score = analysis["skills_comparison"].get("match_percentage", 0)
                analysis["score_breakdown"]["match_score"] = match_score
                
                # Calculate final score as weighted average
                analysis["score"] = int((score * 0.4) + (match_score * 0.4) + (analysis["score_breakdown"]["format_score"] * 0.2))
                
                # Generate searchability issues
                missing_keywords = analysis["skills_comparison"].get("missing_keywords", [])
                if missing_keywords:
                    if language == 'ar':
                        analysis["searchability_issues"].append(f"الكلمات الرئيسية المفقودة: {', '.join(missing_keywords[:5])}")
                        if len(missing_keywords) > 5:
                            analysis["searchability_issues"].append(f"و {len(missing_keywords) - 5} كلمات رئيسية مفقودة أخرى")
                    else:
                        analysis["searchability_issues"].append(f"Missing important keywords: {', '.join(missing_keywords[:5])}")
                        if len(missing_keywords) > 5:
                            analysis["searchability_issues"].append(f"And {len(missing_keywords) - 5} more missing keywords")
                else:
                    if language == 'ar':
                        analysis["searchability_issues"].append("لم يتم العثور على مشاكل رئيسية في الكلمات الرئيسية")
                    else:
                        analysis["searchability_issues"].append("No major keyword issues found")
                
                # Generate recommendations using TextAnalyzer
                match_percentage = analysis["skills_comparison"].get("match_percentage", 0)
                analysis["recommendations"] = text_analyzer.generate_recommendations(
                    text, 
                    job_description, 
                    match_percentage
                )
            
            # Use Gemini for enhanced analysis if available
            if gemini_handler:
                try:
                    # Get structured data from Gemini analysis
                    gemini_analysis = gemini_handler.analyze_resume(
                        [text[:1000]],  # Send first 1000 chars as sample
                        job_description,
                        "analysis",
                        language
                    )
                    
                    if gemini_analysis and gemini_analysis.get("success", False):
                        # Extract structured data from Gemini analysis
                        structured_data = gemini_handler.extract_structured_data(
                            gemini_analysis.get("content", ""),
                            language
                        )
                        
                        # Update analysis with structured data
                        for key in ["education_comparison", "experience_comparison", "recommendations"]:
                            if key in structured_data and structured_data[key]:
                                analysis[key] = structured_data[key]
                    else:
                        # Fallback to basic analysis if Gemini fails
                        _add_fallback_analysis_data(analysis, language)
                except Exception as e:
                    logger.error(f"Gemini analysis failed: {e}")
                    # Fallback to basic analysis if Gemini fails
                    _add_fallback_analysis_data(analysis, language)
            else:
                # Fallback to basic analysis if Gemini is not available
                _add_fallback_analysis_data(analysis, language)
        else:
            # Basic recommendations without job description
            analysis["recommendations"] = text_analyzer.generate_recommendations(text)
            
            # Basic searchability issues without job description
            if language == 'ar':
                analysis["searchability_issues"] = [
                    "لم يتم تقديم وصف وظيفي للمقارنة",
                    "قم بالتحميل مع وصف وظيفي للحصول على تحليل أكثر تحديدًا"
                ]
            else:
                analysis["searchability_issues"] = [
                    "No job description provided for comparison",
                    "Upload with a job description for more specific analysis"
                ]
            
            # Add basic education and experience analysis
            _add_fallback_analysis_data(analysis, language)
        
        # Store the result
        results_store[analysis_id] = analysis
        return analysis
       
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        return {
            "id": str(uuid.uuid4()),
            "error": f"Analysis failed: {str(e)}",
            "success": False,
            "language": language,
            "direction": "rtl" if language == 'ar' else "ltr"
        }

def _calculate_format_score(text: str, language: str) -> int:
    """Calculate a score for CV format and structure."""
    score = 70  # Base score
    
    # Check for section headers
    section_headers = {
        'en': ['education', 'experience', 'skills', 'work', 'employment', 'qualification'],
        'ar': ['التعليم', 'الخبرة', 'المهارات', 'العمل', 'التوظيف', 'المؤهلات']
    }
    
    headers_found = 0
    for header in section_headers.get(language, section_headers['en']):
        if re.search(r'\b' + header + r'\b', text, re.IGNORECASE):
            headers_found += 1
    
    # Adjust score based on headers found
    if headers_found >= 3:
        score += 20
    elif headers_found >= 2:
        score += 10
    
    # Check for bullet points
    bullet_points = len(re.findall(r'•|\*|-|\u2022', text))
    if bullet_points > 10:
        score += 10
    elif bullet_points > 5:
        score += 5
    
    return min(score, 100)  # Cap at 100

def _add_fallback_analysis_data(analysis: Dict[str, Any], language: str) -> None:
    """Add fallback data for education and experience analysis when Gemini is not available."""
    if language == 'ar':
        if not analysis["education_comparison"]:
            analysis["education_comparison"] = [
                "تأكد من ذكر جميع المؤهلات التعليمية ذات الصلة",
                "أضف تفاصيل حول الدورات والشهادات المتخصصة"
            ]
        
        if not analysis["experience_comparison"]:
            analysis["experience_comparison"] = [
                "استخدم أفعال قوية لوصف مسؤولياتك وإنجازاتك",
                "قم بتنظيم خبراتك بترتيب زمني عكسي (الأحدث أولاً)"
            ]
        
        # Add more recommendations if needed
        if len(analysis["recommendations"]) < 3:
            analysis["recommendations"].extend([
                "استخدم تنسيقًا متسقًا في جميع أنحاء سيرتك الذاتية",
                "تأكد من أن معلومات الاتصال الخاصة بك محدثة وواضحة"
            ])
    else:
        if not analysis["education_comparison"]:
            analysis["education_comparison"] = [
                "Ensure all relevant educational qualifications are mentioned",
                "Add details about specialized courses and certifications"
            ]
        
        if not analysis["experience_comparison"]:
            analysis["experience_comparison"] = [
                "Use strong action verbs to describe your responsibilities and achievements",
                "Organize your experiences in reverse chronological order (most recent first)"
            ]
        
        # Add more recommendations if needed
        if len(analysis["recommendations"]) < 3:
            analysis["recommendations"].extend([
                "Use consistent formatting throughout your resume",
                "Ensure your contact information is up-to-date and clear"
            ])

def _get_localized_summary(top_keywords: List[str], keyword_count: int, language: str) -> str:
    """Generate a localized summary based on language."""
    if language == 'ar':
        keywords_text = '، '.join(top_keywords)
        return f"سيرتك الذاتية تظهر مهارات قوية في: {keywords_text}. تحتوي على {keyword_count} مصطلح فريد متعلق بالصناعة."
    else:
        keywords_text = ', '.join(top_keywords)
        return f"Your CV demonstrates strong skills in: {keywords_text}. Contains {keyword_count} unique industry-relevant terms."

@app.route('/api/analyze', methods=['POST'])
def analyze_endpoint():
    """API endpoint for CV analysis with multilingual support."""
    try:
        # Read the file content once to avoid stream issues
        if 'cv' not in request.files:
            logger.warning("API Analyze: No 'cv' part in request.files. Aborting with 400.")
            return jsonify({"error": "No file uploaded"}), 400
        
        file = request.files['cv']

        if file.filename == "":
            logger.warning("API Analyze: No file selected (empty filename). Aborting with 400.")
            return jsonify({"error": "No file selected"}), 400
            
        if not file_processor.allowed_file(file.filename):
            logger.warning(f"API Analyze: Invalid file type for {file.filename}. Allowed: {ALLOWED_EXTENSIONS}. Aborting with 400.")
            return jsonify({"error": f"Invalid file type. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"}), 400
        
        # Read the file content once to avoid stream issues
        file_content_bytes = file.read()
        # Reset the original FileStorage stream pointer
        file.seek(0)

        # Use BytesIO for size checking
        file_stream_for_size_check = BytesIO(file_content_bytes)
        if not file_processor.check_file_size(file_stream_for_size_check):
            logger.warning(f"API Analyze: File size exceeded for {file.filename}. Limit: {MAX_FILE_SIZE // (1024 * 1024)}MB. Aborting with 400.")
            return jsonify({"error": f"File size exceeds {MAX_FILE_SIZE // (1024 * 1024)}MB limit"}), 400

        filename = secure_filename(file.filename)
        
        # Use BytesIO for text extraction
        file_stream_for_text_extraction = BytesIO(file_content_bytes)
        text, detected_language = file_processor.extract_text(file_stream_for_text_extraction, filename)
        
        if not text:
            logger.warning(f"API Analyze: Failed to extract text from file {filename}. Aborting with 400.")
            return jsonify({"error": "Failed to extract text from file"}), 400
        
        logger.info(f"Successfully validated and extracted text from {filename}. Language: {detected_language}")
        
        # Get language hint from request if provided
        language_hint = request.form.get("language_hint", "")
        
        # Use language hint if provided and valid, otherwise use detected language
        language = language_hint if language_hint in ["en", "ar"] else detected_language
        logger.info(f"Using language: {language} for analysis.")
            
        job_description = request.form.get("job_description")
        if job_description:
            logger.info("Job description provided.")
        else:
            logger.info("No job description provided.")
        
        analysis = analyze_cv(text, job_description, language)
        
        if not analysis.get("success", True):
            # This case should ideally return a 500 as it's an internal analysis failure
            logger.error(f"API Analyze: Core analysis failed for {filename}. Error: {analysis.get('error', 'Unknown analysis error')}")
            return jsonify({"error": analysis.get("error", "Analysis failed internally")}), 500
            
        logger.info(f"API Analyze: Successfully analyzed {filename}. Returning 200.")
        return jsonify(analysis)
        
    except Exception as e:
        logger.exception(f"API Analyze: Unhandled exception in /api/analyze endpoint.")
        return jsonify({
            "error": f"Internal server error: {str(e)}",
            "language": "en",
            "direction": "ltr"
        }), 500

@app.route('/api/results/<result_id>', methods=['GET'])
def get_results(result_id):
    """API endpoint to retrieve analysis results by ID."""
    try:
        result = results_store.get(result_id)
        if result is None:
            return jsonify({"error": "Result not found"}), 404
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error retrieving result: {e}")
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """API endpoint for health check."""
    return jsonify({
        "status": "operational",
        "version": "1.4.0",
        "timestamp": datetime.now().isoformat(),
        "features": {
            "multilingual": True,
            "arabic_support": True,
            "detailed_analysis": gemini_handler is not None
        }
    })

@app.route('/')
def home():
    """Home endpoint with API information."""
    return jsonify({
        "status": "operational",
        "version": "1.4.0",
        "supported_files": list(ALLOWED_EXTENSIONS),
        "max_size_mb": MAX_FILE_SIZE // (1024 * 1024),
        "supported_languages": ["en", "ar"],
        "endpoints": {
            "POST /api/analyze": "Upload and analyze CV",
            "GET /api/results/<result_id>": "Retrieve analysis results",
            "GET /api/health": "Health check"
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
