# backend/utils/file_processor.py

import io
from typing import Optional, Dict, Any, Tuple
import base64
from PyPDF2 import PdfReader
from docx import Document
from pdf2image import convert_from_bytes
import logging
import re

logger = logging.getLogger(__name__)

class FileProcessor:
    """Handles file processing operations for different file types with multilingual support."""
    
    ALLOWED_EXTENSIONS = {'pdf', 'docx'}
    MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB

    @staticmethod
    def allowed_file(filename: str) -> bool:
        """Check if the file has an allowed extension."""
        return '.' in filename and filename.rsplit('.', 1)[1].lower() in FileProcessor.ALLOWED_EXTENSIONS

    @staticmethod
    def check_file_size(file_stream) -> bool:
        """Check if file size is within limits."""
        file_stream.seek(0, 2)  # Go to end of file
        size = file_stream.tell()
        file_stream.seek(0)  # Reset to beginning
        return size <= FileProcessor.MAX_FILE_SIZE

    @staticmethod
    def extract_text(file_stream, filename: str) -> Tuple[Optional[str], str]:
        """
        Extract text content from PDF or DOCX files with language detection.
        
        Args:
            file_stream: File stream to read from
            filename: Name of the file
            
        Returns:
            Tuple of (extracted text, detected language)
        """
        try:
            file_bytes = io.BytesIO(file_stream.read())
            file_stream.seek(0)  # Reset stream position

            if filename.lower().endswith('.pdf'):
                reader = PdfReader(file_bytes)
                text = " ".join([page.extract_text() or '' for page in reader.pages])
            elif filename.lower().endswith('.docx'):
                doc = Document(file_bytes)
                text = " ".join([para.text for para in doc.paragraphs if para.text])
            else:
                return None, 'en'

            # Clean text while preserving Arabic characters
            cleaned_text = FileProcessor.clean_text(text)
            
            # Detect language
            language = FileProcessor.detect_language(cleaned_text)
            
            return cleaned_text, language

        except Exception as e:
            logger.error(f"Text extraction failed: {str(e)}")
            return None, 'en'

    @staticmethod
    def clean_text(text: str) -> str:
        """
        Clean and normalize extracted text while preserving Arabic characters.
        
        Args:
            text: Text to clean
            
        Returns:
            Cleaned text
        """
        # Remove control characters but preserve Arabic and Latin characters
        text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', ' ', text)
        
        # Replace multiple spaces with a single space
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text

    @staticmethod
    def detect_language(text: str) -> str:
        """
        Detect if text is primarily Arabic or English.
        
        Args:
            text: Text to analyze
            
        Returns:
            'ar' for Arabic, 'en' for English
        """
        # Arabic Unicode range
        arabic_pattern = re.compile(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+')
        # Latin Unicode range (English)
        latin_pattern = re.compile(r'[a-zA-Z]+')
        
        arabic_matches = len(arabic_pattern.findall(text))
        latin_matches = len(latin_pattern.findall(text))
        
        # If more Arabic characters than Latin, consider it Arabic
        return 'ar' if arabic_matches > latin_matches else 'en'

    @staticmethod
    def convert_pdf_to_image_parts(file_stream) -> Optional[list]:
        """Convert PDF first page to base64 encoded image for Gemini Vision API."""
        try:
            # Convert PDF to images
            images = convert_from_bytes(file_stream.read())
            first_page = images[0]

            # Convert to bytes
            img_byte_arr = io.BytesIO()
            first_page.save(img_byte_arr, format='JPEG')
            img_byte_arr = img_byte_arr.getvalue()

            # Create the parts list for Gemini
            pdf_parts = [{
                "mime_type": "image/jpeg",
                "data": base64.b64encode(img_byte_arr).decode()
            }]
            return pdf_parts

        except Exception as e:
            logger.error(f"PDF to image conversion failed: {str(e)}")
            return None
        