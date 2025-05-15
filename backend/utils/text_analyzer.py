# backend/utils/text_analyzer.py

import spacy
from typing import Dict, List, Any, Optional
import logging
import re
from spacy.language import Language
from spacy.tokens import Doc

logger = logging.getLogger(__name__)

class TextAnalyzer:
    """Provides text analysis capabilities using spaCy with multilingual support."""

    def __init__(self):
        """Initialize the spaCy models for English and Arabic."""
        try:
            # Load English model
            self.nlp_en = spacy.load("en_core_web_sm")
            
            # Try to load Arabic model if available
            try:
                self.nlp_ar = spacy.load("ar_core_news_sm")
                logger.info("Arabic language model loaded successfully")
            except OSError:
                # If Arabic model is not available, create a blank one
                logger.warning("Arabic model not found, using blank model")
                self.nlp_ar = spacy.blank("ar")
                
                # Add basic components to the blank model
                self.nlp_ar.add_pipe("sentencizer")
            
            logger.info("Text analyzer initialized with multilingual support")
        except Exception as e:
            logger.error(f"Failed to load spaCy models: {str(e)}")
            raise

    def detect_language(self, text: str) -> str:
        """
        Detect if text is primarily Arabic or English.
        
        Args:
            text: The text to analyze
            
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

    def get_nlp_model(self, text: str) -> Language:
        """Get the appropriate NLP model based on text language."""
        language = self.detect_language(text)
        return self.nlp_ar if language == 'ar' else self.nlp_en

    def extract_keywords(self, text: str) -> List[str]:
        """
        Extract important keywords from text with language detection.
        
        Args:
            text: The text to analyze
            
        Returns:
            List of extracted keywords
        """
        if not text or text.strip() == "":
            return []
            
        # Detect language and get appropriate model
        nlp = self.get_nlp_model(text)
        doc = nlp(text)
        
        # For Arabic, we need different POS tags
        if self.detect_language(text) == 'ar':
            keywords = [
                token.text.lower()
                for token in doc
                if token.pos_ in {"NOUN", "VERB", "PROPN", "ADJ"}
                and not token.is_stop
                and len(token.text) > 1
            ]
        else:
            # English processing
            keywords = [
                token.lemma_.lower()
                for token in doc
                if token.pos_ in {"NOUN", "VERB", "PROPN"}
                and not token.is_stop
                and len(token.text) > 2
            ]
        
        return list(set(keywords))

    def analyze_text(self, resume_text: str, job_description: str) -> Dict[str, Any]:
        """
        Analyze resume text against job description with language support.
        
        Args:
            resume_text: The extracted text from the resume
            job_description: The job description text
        
        Returns:
            Dictionary containing analysis results
        """
        try:
            # Detect language
            resume_language = self.detect_language(resume_text)
            job_language = self.detect_language(job_description)
            
            # Log language detection results
            logger.info(f"Resume language detected: {resume_language}")
            logger.info(f"Job description language detected: {job_language}")
            
            # Process both texts with appropriate models
            resume_keywords = set(self.extract_keywords(resume_text))
            job_keywords = set(self.extract_keywords(job_description))

            # Find matching and missing keywords
            matching_keywords = resume_keywords.intersection(job_keywords)
            missing_keywords = job_keywords - resume_keywords

            # Calculate match percentage
            match_percentage = (
                len(matching_keywords) / len(job_keywords) * 100
                if job_keywords
                else 0
            )

            # Prepare skills comparison result
            skills_comparison = {
                "match_percentage": round(match_percentage, 2),
                "matching_keywords": list(matching_keywords),
                "missing_keywords": list(missing_keywords),
                "total_keywords_found": len(resume_keywords),
            }
            
            # Add language information
            result = {
                "skills_comparison": skills_comparison,
                "language": resume_language,
                "direction": "rtl" if resume_language == "ar" else "ltr",
                "success": True
            }
            
            return result

        except Exception as e:
            logger.error(f"Text analysis failed: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
            
    def generate_recommendations(self, 
                               resume_text: str, 
                               job_description: Optional[str] = None, 
                               match_percentage: Optional[float] = None) -> List[str]:
        """
        Generate recommendations based on resume and job description.
        
        Args:
            resume_text: The extracted text from the resume
            job_description: Optional job description text
            match_percentage: Optional match percentage from skills comparison
            
        Returns:
            List of recommendations
        """
        recommendations = []
        language = self.detect_language(resume_text)
        
        # Basic recommendations based on language
        if language == 'ar':
            if not job_description:
                recommendations = [
                    "أضف المزيد من المهارات التقنية المحددة" if match_percentage and match_percentage < 50 else "سيرتك الذاتية تحتوي على مجموعة جيدة من الكلمات الرئيسية",
                    "فكر في إضافة المزيد من المصطلحات الخاصة بالصناعة"
                ]
            else:
                if match_percentage is not None:
                    if match_percentage < 50:
                        recommendations.append("أضف المزيد من الكلمات الرئيسية المتعلقة بالوظيفة لتحسين التوافق مع أنظمة تتبع المتقدمين")
                        recommendations.append("فكر في إعادة هيكلة سيرتك الذاتية لإبراز الخبرة ذات الصلة")
                    elif match_percentage < 75:
                        recommendations.append("سيرتك الذاتية لديها تطابق جيد في الكلمات الرئيسية ولكن يمكن تحسينها")
                        recommendations.append("فكر في إضافة المزيد من المصطلحات التقنية المحددة من الوصف الوظيفي")
                    else:
                        recommendations.append("تطابق ممتاز للكلمات الرئيسية مع الوصف الوظيفي")
                        recommendations.append("سيرتك الذاتية محسنة جيدًا لهذا المنصب")
        else:
            # English recommendations
            if not job_description:
                recommendations = [
                    "Add more specific technical skills" if match_percentage and match_percentage < 50 else "Your CV contains a good range of keywords",
                    "Consider adding more industry-specific terms"
                ]
            else:
                if match_percentage is not None:
                    if match_percentage < 50:
                        recommendations.append("Add more job-specific keywords to improve ATS compatibility")
                        recommendations.append("Consider restructuring your CV to highlight relevant experience")
                    elif match_percentage < 75:
                        recommendations.append("Your CV has good keyword matching but could be improved")
                        recommendations.append("Consider adding more specific technical terms from the job description")
                    else:
                        recommendations.append("Excellent keyword matching with the job description")
                        recommendations.append("Your CV is well-optimized for this position")
        
        # Add general recommendations
        if language == 'ar':
            recommendations.append("استخدم أفعال نشطة في بداية نقاط الخبرة")
            recommendations.append("قم بتحديد إنجازاتك بمقاييس محددة حيثما أمكن")
        else:
            recommendations.append("Use action verbs at the beginning of experience bullet points")
            recommendations.append("Quantify achievements with specific metrics where possible")
            
        return recommendations
