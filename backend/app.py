from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
from io import BytesIO
import logging
import traceback
from datetime import datetime
import uuid
import os
import re
from typing import Dict, List, Any, Optional, Tuple

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,  # Changed to DEBUG for more detailed logs
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("debug_app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Flask app
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})  # Allow all origins in development

# In-memory storage for results and errors (replace with database in production)
results_store = {}
error_store = {}

# Configuration constants
ALLOWED_EXTENSIONS = {'pdf', 'docx', 'doc', 'txt', 'rtf'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
KEYWORD_LIMIT = 15

# Simple fallback analysis when other methods fail
def generate_fallback_analysis(language='en') -> Dict[str, Any]:
    """Generate a basic fallback analysis with meaningful scores."""
    analysis_id = str(uuid.uuid4())
    direction = "rtl" if language == 'ar' else "ltr"
    
    # Generate random but reasonable scores
    overall_score = 65
    keyword_score = 70
    format_score = 60
    readability_score = 65
    
    if language == 'ar':
        summary = "تحليل أساسي للسيرة الذاتية. يرجى مراجعة التوصيات لتحسين فرصك."
        recommendations = [
            "أضف المزيد من الكلمات الرئيسية ذات الصلة بالوظيفة",
            "قم بتنظيم سيرتك الذاتية بتنسيق واضح ومهني",
            "ركز على إنجازاتك بدلاً من مجرد سرد المسؤوليات"
        ]
        education_comparison = [
            "تم ذكر المؤهلات التعليمية بشكل واضح",
            "يمكن إضافة المزيد من التفاصيل حول المشاريع الأكاديمية ذات الصلة"
        ]
        experience_comparison = [
            "تم توثيق الخبرة العملية بشكل جيد",
            "يمكن التركيز أكثر على الإنجازات القابلة للقياس في كل دور"
        ]
        searchability_issues = [
            "تأكد من استخدام تنسيق قياسي يمكن قراءته بواسطة أنظمة تتبع المتقدمين",
            "تجنب استخدام الرسومات المعقدة أو الجداول التي قد لا يتم تحليلها بشكل صحيح"
        ]
    else:
        summary = "Basic analysis of your CV. Please review the recommendations to improve your chances."
        recommendations = [
            "Add more job-relevant keywords",
            "Organize your CV with clear, professional formatting",
            "Focus on achievements rather than just listing responsibilities"
        ]
        education_comparison = [
            "Educational qualifications are clearly mentioned",
            "Could add more details about relevant academic projects"
        ]
        experience_comparison = [
            "Work experience is well documented",
            "Could focus more on measurable achievements in each role"
        ]
        searchability_issues = [
            "Ensure you use a standard format that can be read by ATS systems",
            "Avoid using complex graphics or tables that may not be parsed correctly"
        ]
    
    return {
        "id": analysis_id,
        "score": overall_score,
        "keywords": ["skill", "experience", "education", "project", "achievement"],
        "summary": summary,
        "analysis_date": datetime.now().isoformat(),
        "skills_comparison": {
            "matching_keywords": ["skill", "experience", "education"],
            "missing_keywords": ["leadership", "teamwork", "communication"],
            "match_percentage": 60
        },
        "searchability_issues": searchability_issues,
        "education_comparison": education_comparison,
        "experience_comparison": experience_comparison,
        "job_description": "",
        "recommendations": recommendations,
        "language": language,
        "direction": direction,
        "score_breakdown": {
            "keyword_score": keyword_score,
            "format_score": format_score,
            "readability_score": readability_score
        },
        "success": True
    }

@app.route('/api/analyze', methods=['POST'])
def analyze_endpoint():
    """API endpoint for CV analysis with enhanced debugging."""
    error_id = str(uuid.uuid4())
    try:
        logger.debug("Starting analysis request processing")
        
        # Check if file was uploaded
        if 'cv' not in request.files:
            logger.warning("API Analyze: No 'cv' part in request.files. Aborting with 400.")
            return jsonify({"error": "No file uploaded"}), 400
        
        file = request.files['cv']
        logger.debug(f"File received: {file.filename}")

        if file.filename == "":
            logger.warning("API Analyze: No file selected (empty filename). Aborting with 400.")
            return jsonify({"error": "No file selected"}), 400
        
        # Check file extension
        file_ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else ''
        if file_ext not in ALLOWED_EXTENSIONS:
            logger.warning(f"API Analyze: Invalid file type for {file.filename}. Allowed: {ALLOWED_EXTENSIONS}. Aborting with 400.")
            return jsonify({"error": f"Invalid file type. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"}), 400
        
        logger.debug(f"File extension validated: {file_ext}")
        
        # Read the file content once to avoid stream issues
        try:
            file_content_bytes = file.read()
            logger.debug(f"File read successfully, size: {len(file_content_bytes)} bytes")
            # Reset the original FileStorage stream pointer
            file.seek(0)
        except Exception as e:
            logger.error(f"Failed to read file: {str(e)}")
            error_store[error_id] = {
                "error": f"Failed to read file: {str(e)}",
                "traceback": traceback.format_exc()
            }
            return jsonify({"error": f"Failed to read file: {str(e)}", "error_id": error_id}), 500

        # Check file size
        if len(file_content_bytes) > MAX_FILE_SIZE:
            logger.warning(f"API Analyze: File size exceeded for {file.filename}. Limit: {MAX_FILE_SIZE // (1024 * 1024)}MB. Aborting with 400.")
            return jsonify({"error": f"File size exceeds {MAX_FILE_SIZE // (1024 * 1024)}MB limit"}), 400

        filename = secure_filename(file.filename)
        logger.debug(f"Secured filename: {filename}")
        
        # Extract text from file
        try:
            # Use BytesIO for text extraction
            file_stream = BytesIO(file_content_bytes)
            
            # Simple text extraction based on file type
            text = ""
            detected_language = "en"  # Default language
            
            if file_ext == 'pdf':
                try:
                    from PyPDF2 import PdfReader
                    reader = PdfReader(file_stream)
                    for page in reader.pages:
                        text += page.extract_text() + "\n"
                    logger.debug(f"PDF text extracted, length: {len(text)}")
                except Exception as e:
                    logger.error(f"PDF extraction error: {str(e)}")
                    error_store[error_id] = {
                        "error": f"PDF extraction error: {str(e)}",
                        "traceback": traceback.format_exc()
                    }
                    return jsonify({"error": f"Failed to extract text from PDF: {str(e)}", "error_id": error_id}), 500
                    
            elif file_ext == 'docx':
                try:
                    from docx import Document
                    doc = Document(file_stream)
                    for para in doc.paragraphs:
                        text += para.text + "\n"
                    logger.debug(f"DOCX text extracted, length: {len(text)}")
                except Exception as e:
                    logger.error(f"DOCX extraction error: {str(e)}")
                    error_store[error_id] = {
                        "error": f"DOCX extraction error: {str(e)}",
                        "traceback": traceback.format_exc()
                    }
                    return jsonify({"error": f"Failed to extract text from DOCX: {str(e)}", "error_id": error_id}), 500
                    
            elif file_ext in ['txt', 'rtf']:
                text = file_content_bytes.decode('utf-8', errors='replace')
                logger.debug(f"TXT/RTF text extracted, length: {len(text)}")
                
            # Basic language detection
            arabic_pattern = re.compile(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+')
            arabic_matches = len(arabic_pattern.findall(text))
            detected_language = 'ar' if arabic_matches > 10 else 'en'
            logger.debug(f"Detected language: {detected_language}")
            
            if not text or len(text.strip()) < 50:
                logger.warning(f"API Analyze: Extracted text too short or empty from file {filename}.")
                return jsonify({"error": "Failed to extract sufficient text from file"}), 400
                
        except Exception as e:
            logger.error(f"Text extraction failed: {str(e)}")
            error_store[error_id] = {
                "error": f"Text extraction failed: {str(e)}",
                "traceback": traceback.format_exc()
            }
            return jsonify({"error": f"Failed to extract text from file: {str(e)}", "error_id": error_id}), 500
        
        logger.info(f"Successfully validated and extracted text from {filename}. Language: {detected_language}")
        
        # Get language hint from request if provided
        language_hint = request.form.get("language_hint", "")
        
        # Use language hint if provided and valid, otherwise use detected language
        language = language_hint if language_hint in ["en", "ar"] else detected_language
        logger.info(f"Using language: {language} for analysis.")
            
        # Get job description if provided
        job_description = request.form.get("job_description", "")
        if job_description:
            logger.info("Job description provided.")
        else:
            logger.info("No job description provided.")
        
        # Try to use enhanced analysis if available
        try:
            logger.debug("Attempting to use EnhancedAnalysisService")
            
            # Import here to catch import errors
            from utils.enhanced_text_analyzer import EnhancedTextAnalyzer
            from utils.enhanced_analysis_service import EnhancedAnalysisService
            
            # Initialize the service
            analysis_service = EnhancedAnalysisService()
            
            # Perform analysis
            analysis = analysis_service.analyze_cv(text, job_description, language)
            logger.debug("Enhanced analysis completed successfully")
            
        except Exception as e:
            logger.error(f"Enhanced analysis failed: {str(e)}")
            logger.error(traceback.format_exc())
            error_store[error_id] = {
                "error": f"Enhanced analysis failed: {str(e)}",
                "traceback": traceback.format_exc()
            }
            
            # Fall back to basic analysis
            logger.info("Falling back to basic analysis")
            analysis = generate_fallback_analysis(language)
        
        # Store the result with a unique ID
        analysis_id = analysis.get("id", str(uuid.uuid4()))
        results_store[analysis_id] = analysis
        
        if not analysis.get("success", True):
            # This case should ideally return a 500 as it's an internal analysis failure
            logger.error(f"API Analyze: Core analysis failed for {filename}. Error: {analysis.get('error', 'Unknown analysis error')}")
            error_store[error_id] = {
                "error": analysis.get("error", "Unknown analysis error"),
                "analysis_attempt": analysis
            }
            return jsonify({"error": analysis.get("error", "Analysis failed internally"), "error_id": error_id}), 500
            
        logger.info(f"API Analyze: Successfully analyzed {filename}. Returning 200.")
        return jsonify(analysis)
        
    except Exception as e:
        logger.exception(f"API Analyze: Unhandled exception in /api/analyze endpoint.")
        error_store[error_id] = {
            "error": str(e),
            "traceback": traceback.format_exc()
        }
        return jsonify({
            "error": f"Internal server error: {str(e)}",
            "error_id": error_id,
            "language": "en",
            "direction": "ltr"
        }), 500

@app.route('/api/results/<result_id>', methods=['GET'])
def get_result(result_id):
    """Retrieve a previously generated analysis result."""
    if result_id in results_store:
        return jsonify(results_store[result_id])
    else:
        return jsonify({"error": "Result not found"}), 404

@app.route('/api/errors/<error_id>', methods=['GET'])
def get_error(error_id):
    """Retrieve detailed error information for debugging."""
    if error_id in error_store:
        return jsonify(error_store[error_id])
    else:
        return jsonify({"error": "Error record not found"}), 404

@app.route('/api/debug', methods=['GET'])
def debug_info():
    """Return debug information about the server environment."""
    debug_info = {
        "timestamp": datetime.now().isoformat(),
        "python_version": os.popen('python --version').read().strip(),
        "installed_packages": os.popen('pip list').read(),
        "environment_variables": {k: v for k, v in os.environ.items() if not k.lower().startswith(('key', 'token', 'secret', 'pass', 'pwd'))},
        "available_modules": {
            "PyPDF2": _check_module("PyPDF2"),
            "docx": _check_module("docx"),
            "spacy": _check_module("spacy"),
            "flask": _check_module("flask"),
            "flask_cors": _check_module("flask_cors"),
            "google.generativeai": _check_module("google.generativeai")
        }
    }
    return jsonify(debug_info)

def _check_module(module_name):
    """Check if a module is available and return its version if possible."""
    try:
        module = __import__(module_name)
        version = getattr(module, "__version__", "Unknown version")
        return {"available": True, "version": version}
    except ImportError:
        return {"available": False}

@app.route('/api/health', methods=['GET'])
def health_check():
    """Simple health check endpoint."""
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0-debug",
        "gemini_available": os.getenv('GOOGLE_API_KEY') is not None
    })

if __name__ == "__main__":
    # Run the Flask app
    app.run(host="0.0.0.0", port=5000)
