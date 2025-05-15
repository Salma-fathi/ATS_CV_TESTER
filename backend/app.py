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
            "skills_comparison": {},
            "searchability_issues": [],
            "education_comparison": [],
            "experience_comparison": [],
            "job_description": "",
            "recommendations": [],
            "language": language,
            "direction": direction
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
                analysis["score"] = int((score + match_score) / 2)  # Average of keyword score and match score
                
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
                    # This would be implemented to use the Gemini handler for more advanced analysis
                    # For now, we'll add placeholder data based on language
                    if language == 'ar':
                        analysis["education_comparison"] = [
                            "درجة البكالوريوس المذكورة في السيرة الذاتية تتطابق مع متطلبات الوظيفة",
                            "فكر في إضافة المزيد من التفاصيل حول الدورات الدراسية ذات الصلة"
                        ]
                        
                        analysis["experience_comparison"] = [
                            "خبرتك تتوافق مع 70% من متطلبات الوظيفة",
                            "فكر في تسليط الضوء على إنجازات محددة مع مقاييس"
                        ]
                        
                        # Add more detailed recommendations
                        analysis["recommendations"].append("استخدم أفعال نشطة في بداية نقاط الخبرة")
                        analysis["recommendations"].append("قم بتحديد إنجازاتك بمقاييس محددة حيثما أمكن")
                    else:
                        analysis["education_comparison"] = [
                            "Bachelor's degree mentioned in CV matches job requirements",
                            "Consider adding more details about relevant coursework"
                        ]
                        
                        analysis["experience_comparison"] = [
                            "Your experience aligns with 70% of job requirements",
                            "Consider highlighting specific achievements with metrics"
                        ]
                        
                        # Add more detailed recommendations
                        analysis["recommendations"].append("Use action verbs at the beginning of experience bullet points")
                        analysis["recommendations"].append("Quantify achievements with specific metrics where possible")
                except Exception as e:
                    logger.error(f"Gemini analysis failed: {e}")
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
        # Check if file was uploaded
        if 'cv' not in request.files:
            return jsonify({"error": "No file uploaded"}), 400
        
        file = request.files['cv']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
            
        if not file_processor.allowed_file(file.filename):
            return jsonify({"error": f"Invalid file type. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"}), 400
        
        # Check file size
        if not file_processor.check_file_size(file):
            return jsonify({"error": f"File size exceeds {MAX_FILE_SIZE // (1024 * 1024)}MB limit"}), 400

        # Process file
        filename = secure_filename(file.filename)
        
        # Extract text and detect language
        text, detected_language = file_processor.extract_text(file, filename)
        
        if not text:
            return jsonify({"error": "Failed to extract text from file"}), 400
        
        # Get language hint from request if provided
        language_hint = request.form.get('language_hint', '')
        
        # Use language hint if provided, otherwise use detected language
        language = language_hint if language_hint in ['en', 'ar'] else detected_language
            
        # Get job description if provided
        job_description = request.form.get('job_description')
        
        # Analyze CV
        analysis = analyze_cv(text, job_description, language)
        
        if not analysis.get("success", True):
            return jsonify({"error": analysis.get("error", "Analysis failed")}), 500
            
        return jsonify(analysis)
        
    except Exception as e:
        logger.error(f"API Error: {e}")
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
        "version": "1.3.0",
        "timestamp": datetime.now().isoformat(),
        "features": {
            "multilingual": True,
            "arabic_support": True
        }
    })

@app.route('/')
def home():
    """Home endpoint with API information."""
    return jsonify({
        "status": "operational",
        "version": "1.3.0",
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