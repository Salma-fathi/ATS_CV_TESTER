# Add to utils/ats_analyzer.py (new file)
import re
from PyPDF2 import PdfReader
import io

class ATSAnalyzer:
    """Analyzes resume for ATS compatibility issues."""
    
    STANDARD_SECTIONS = [
        "experience", "education", "skills", "work experience", 
        "professional experience", "employment history", "qualifications",
        "certifications", "projects", "publications", "languages"
    ]
    
    def __init__(self):
        self.issues = []
        self.parse_rate = 100.0  # Default perfect parse rate
    
    def analyze_pdf_structure(self, pdf_bytes):
        """Analyze PDF structure for potential ATS issues."""
        try:
            reader = PdfReader(io.BytesIO(pdf_bytes))
            
            # Check for potential issues
            issues = []
            
            # Check if text can be extracted
            text_extraction_success = True
            total_text = ""
            
            for page in reader.pages:
                page_text = page.extract_text() or ""
                if not page_text.strip():
                    text_extraction_success = False
                total_text += page_text
            
            # Calculate parse rate based on extraction success
            if not text_extraction_success:
                self.parse_rate = 70.0
                issues.append("Some pages may not be properly parsed by ATS systems")
            
            # Check for potential table structures
            if "----" in total_text or "||||" in total_text or "\t\t\t" in total_text:
                self.parse_rate -= 10.0
                issues.append("Detected potential tables or complex formatting")
            
            # Check for non-standard section headings
            found_standard_sections = False
            for section in self.STANDARD_SECTIONS:
                if re.search(r'\b' + re.escape(section) + r'\b', total_text.lower()):
                    found_standard_sections = True
                    break
            
            if not found_standard_sections:
                self.parse_rate -= 15.0
                issues.append("No standard section headings detected")
            
            # Check for potential character encoding issues
            if re.search(r'[^\x00-\x7F]+', total_text):
                self.parse_rate -= 5.0
                issues.append("Non-standard characters detected that may cause parsing issues")
            
            self.issues = issues
            self.parse_rate = max(0.0, min(100.0, self.parse_rate))  # Ensure between 0-100
            
            return {
                "parse_rate": self.parse_rate,
                "issues": self.issues
            }
            
        except Exception as e:
            self.parse_rate = 50.0
            self.issues = ["Error analyzing PDF structure: " + str(e)]
            return {
                "parse_rate": self.parse_rate,
                "issues": self.issues
            }
