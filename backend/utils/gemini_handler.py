# backend/utils/gemini_handler.py

import os
import google.generativeai as genai
import logging
from typing import Optional, Dict, Any, List

logger = logging.getLogger(__name__)

class GeminiHandler:
    """Handles interactions with Google's Gemini Pro Vision API with multilingual support."""

    def __init__(self):
        """Initialize the Gemini API with the API key."""
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            raise ValueError("GOOGLE_API_KEY environment variable not set")
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro-vision')

    def get_prompts(self, language: str = 'en') -> Dict[str, str]:
        """
        Return predefined prompts for different analysis types with language support.
        
        Args:
            language: Language code ('en' for English, 'ar' for Arabic)
            
        Returns:
            Dictionary of prompts in the specified language
        """
        if language == 'ar':
            return {
                "analysis": """
                أنت مدير موارد بشرية تقني ذو خبرة. مهمتك هي:
                1. مراجعة السيرة الذاتية المقدمة مقابل الوصف الوظيفي
                2. تقييم مؤهلات وخبرة المرشح
                3. تسليط الضوء على نقاط القوة الرئيسية والمجالات المحتملة للتحسين
                4. تقديم توصيات محددة لتحسين التوافق مع الدور
                يرجى تقديم تحليل مفصل ومهني.
                """,
                
                "percentage": """
                أنت محلل خبير في نظام تتبع المتقدمين (ATS). يرجى:
                1. حساب نسبة التطابق بين السيرة الذاتية والوصف الوظيفي
                2. سرد جميع الكلمات الرئيسية المتطابقة
                3. تحديد الكلمات الرئيسية والمهارات المفقودة
                4. تقديم توصيات محددة للتحسين
                قم بتنسيق ردك على النحو التالي:
                نسبة التطابق: XX%
                الكلمات الرئيسية المتطابقة: [قائمة]
                الكلمات الرئيسية المفقودة: [قائمة]
                التوصيات: [اقتراحات مفصلة]
                """
            }
        else:
            return {
                "analysis": """
                You are an experienced Technical Human Resource Manager. Your task is to:
                1. Review the provided resume against the job description
                2. Evaluate the candidate's qualifications and experience
                3. Highlight key strengths and potential areas for improvement
                4. Provide specific recommendations for better alignment with the role
                Please provide a detailed, professional analysis.
                """,
                
                "percentage": """
                You are an expert ATS (Applicant Tracking System) analyzer. Please:
                1. Calculate a match percentage between the resume and job description
                2. List all matching keywords found
                3. Identify missing keywords and skills
                4. Provide specific recommendations for improvement
                Format your response as:
                Match Percentage: XX%
                Matching Keywords: [list]
                Missing Keywords: [list]
                Recommendations: [detailed suggestions]
                """
            }

    def analyze_resume(self, 
                      pdf_content: list, 
                      job_description: str, 
                      analysis_type: str = "analysis",
                      language: str = 'en') -> Optional[Dict[str, Any]]:
        """
        Analyze the resume using Gemini Pro Vision with language support.
        
        Args:
            pdf_content: List containing the PDF's first page as base64 encoded image
            job_description: The job description text
            analysis_type: Type of analysis to perform ("analysis" or "percentage")
            language: Language code ('en' for English, 'ar' for Arabic)
        
        Returns:
            Dictionary containing the analysis results or None if failed
        """
        try:
            # Get the appropriate prompt in the correct language
            prompts = self.get_prompts(language)
            primary_prompt = prompts.get(analysis_type, prompts["analysis"])

            # Add language instruction to the prompt
            language_instruction = ""
            if language == 'ar':
                language_instruction = "يرجى تقديم التحليل باللغة العربية."
            else:
                language_instruction = "Please provide the analysis in English."

            # Generate content using Gemini Pro Vision
            response = self.model.generate_content([
                primary_prompt,
                language_instruction,
                pdf_content[0],  # The base64 encoded image
                f"{'وصف الوظيفة' if language == 'ar' else 'Job Description'}: {job_description}"
            ])

            # Process and return the response
            return {
                "analysis_type": analysis_type,
                "content": response.text,
                "language": language,
                "direction": "rtl" if language == 'ar' else "ltr",
                "success": True
            }

        except Exception as e:
            logger.error(f"Gemini API call failed: {str(e)}")
            return None
            
    def extract_structured_data(self, analysis_result: str, language: str = 'en') -> Dict[str, Any]:
        """
        Extract structured data from Gemini analysis result.
        
        Args:
            analysis_result: The text result from Gemini analysis
            language: Language code ('en' for English, 'ar' for Arabic)
            
        Returns:
            Dictionary with structured data extracted from the analysis
        """
        try:
            # Initialize structured data
            structured_data = {
                "education_comparison": [],
                "experience_comparison": [],
                "recommendations": [],
                "language": language,
                "direction": "rtl" if language == 'ar' else "ltr"
            }
            
            # Create a new Gemini text model for extraction
            text_model = genai.GenerativeModel('gemini-pro')
            
            # Create extraction prompt based on language
            if language == 'ar':
                extraction_prompt = f"""
                قم بتحليل النص التالي وإستخراج المعلومات التالية:
                1. مقارنة التعليم: قائمة بالنقاط المتعلقة بتعليم المرشح
                2. مقارنة الخبرة: قائمة بالنقاط المتعلقة بخبرة المرشح
                3. التوصيات: قائمة بالتوصيات لتحسين السيرة الذاتية
                
                قم بتنسيق الإجابة كـ JSON بالتنسيق التالي:
                {{
                  "education_comparison": ["نقطة 1", "نقطة 2"],
                  "experience_comparison": ["نقطة 1", "نقطة 2"],
                  "recommendations": ["توصية 1", "توصية 2"]
                }}
                
                النص للتحليل:
                {analysis_result}
                """
            else:
                extraction_prompt = f"""
                Analyze the following text and extract these pieces of information:
                1. Education Comparison: List of points related to the candidate's education
                2. Experience Comparison: List of points related to the candidate's experience
                3. Recommendations: List of recommendations for improving the resume
                
                Format the answer as JSON in the following format:
                {{
                  "education_comparison": ["point 1", "point 2"],
                  "experience_comparison": ["point 1", "point 2"],
                  "recommendations": ["recommendation 1", "recommendation 2"]
                }}
                
                Text to analyze:
                {analysis_result}
                """
            
            # Generate extraction
            extraction_response = text_model.generate_content(extraction_prompt)
            
            # Parse the JSON response
            import json
            import re
            
            # Extract JSON from the response
            json_match = re.search(r'({.*})', extraction_response.text, re.DOTALL)
            if json_match:
                json_str = json_match.group(1)
                extracted_data = json.loads(json_str)
                
                # Update structured data with extracted information
                for key in ["education_comparison", "experience_comparison", "recommendations"]:
                    if key in extracted_data and isinstance(extracted_data[key], list):
                        structured_data[key] = extracted_data[key]
            
            return structured_data
            
        except Exception as e:
            logger.error(f"Structured data extraction failed: {str(e)}")
            return {
                "education_comparison": [],
                "experience_comparison": [],
                "recommendations": [],
                "language": language,
                "direction": "rtl" if language == 'ar' else "ltr"
            }