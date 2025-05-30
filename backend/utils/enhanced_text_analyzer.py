import spacy
from typing import Dict, List, Any, Optional, Tuple
import logging
import re
from spacy.language import Language
from spacy.tokens import Doc
import random
from datetime import datetime

logger = logging.getLogger(__name__)

class EnhancedTextAnalyzer:
    """Provides enhanced text analysis capabilities for CV analysis with multilingual support."""

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
            
            logger.info("Enhanced text analyzer initialized with multilingual support")
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
                if token.pos_ in {"NOUN", "VERB", "PROPN", "ADJ"}
                and not token.is_stop
                and len(token.text) > 2
            ]
        
        return list(set(keywords))

    def analyze_cv_formatting(self, resume_text: str) -> Dict[str, Any]:
        """
        Analyze CV formatting quality.
        
        Args:
            resume_text: The extracted text from the resume
            
        Returns:
            Dictionary with formatting analysis results
        """
        # Initialize formatting score
        formatting_score = 0
        issues = []
        language = self.detect_language(resume_text)
        
        # Check for section headers (education, experience, skills, etc.)
        section_patterns = {
            'en': [
                r'\b(education|academic|qualification|degree)\b',
                r'\b(experience|employment|work history|professional background)\b',
                r'\b(skills|abilities|competencies|expertise)\b',
                r'\b(projects|portfolio|achievements)\b',
                r'\b(contact|information|profile)\b'
            ],
            'ar': [
                r'(التعليم|المؤهلات|الشهادات)',
                r'(الخبرة|العمل|التاريخ المهني)',
                r'(المهارات|القدرات|الكفاءات)',
                r'(المشاريع|الإنجازات)',
                r'(معلومات الاتصال|الملف الشخصي)'
            ]
        }
        
        patterns = section_patterns['ar'] if language == 'ar' else section_patterns['en']
        sections_found = 0
        
        for pattern in patterns:
            if re.search(pattern, resume_text, re.IGNORECASE):
                sections_found += 1
        
        # Calculate section score (max 30 points)
        section_score = min(30, sections_found * 6)
        formatting_score += section_score
        
        if sections_found < 3:
            if language == 'ar':
                issues.append("يفتقر السيرة الذاتية إلى أقسام واضحة. أضف عناوين مثل 'التعليم'، 'الخبرة'، 'المهارات'.")
            else:
                issues.append("CV lacks clear sections. Add headers like 'Education', 'Experience', 'Skills'.")
        
        # Check for bullet points (indicates well-structured content)
        bullet_patterns = [r'•', r'\\*', r'-', r'\\d+\\.']
        bullets_found = False
        
        for pattern in bullet_patterns:
            if re.search(pattern, resume_text):
                bullets_found = True
                break
        
        # Add bullet point score (max 20 points)
        bullet_score = 20 if bullets_found else 0
        formatting_score += bullet_score
        
        if not bullets_found:
            if language == 'ar':
                issues.append("استخدم النقاط لتنظيم المعلومات بشكل أفضل، خاصة في أقسام الخبرة والمهارات.")
            else:
                issues.append("Use bullet points to better organize information, especially in experience and skills sections.")
        
        # Check for consistent spacing and line breaks
        lines = resume_text.split('\n')
        consistent_spacing = True
        empty_line_count = 0
        
        for i in range(1, len(lines)):
            if not lines[i].strip() and not lines[i-1].strip():
                empty_line_count += 1
                if empty_line_count > 3:
                    consistent_spacing = False
                    break
        
        # Add spacing score (max 20 points)
        spacing_score = 20 if consistent_spacing else 10
        formatting_score += spacing_score
        
        if not consistent_spacing:
            if language == 'ar':
                issues.append("تنسيق غير متناسق. تجنب المساحات الفارغة المتعددة المتتالية.")
            else:
                issues.append("Inconsistent formatting. Avoid multiple consecutive empty spaces.")
        
        # Check for contact information
        contact_patterns = {
            'en': [
                r'[\w\.-]+@[\w\.-]+\.\w+',  # Email
                r'\+?[\d\s()-]{7,}',  # Phone
                r'linkedin\.com/\w+'  # LinkedIn
            ],
            'ar': [
                r'[\w\.-]+@[\w\.-]+\.\w+',  # Email
                r'\+?[\d\s()-]{7,}',  # Phone
                r'linkedin\.com/\w+'  # LinkedIn
            ]
        }
        
        patterns = contact_patterns['ar'] if language == 'ar' else contact_patterns['en']
        contact_found = 0
        
        for pattern in patterns:
            if re.search(pattern, resume_text):
                contact_found += 1
        
        # Add contact score (max 30 points)
        contact_score = min(30, contact_found * 10)
        formatting_score += contact_score
        
        if contact_found < 2:
            if language == 'ar':
                issues.append("معلومات الاتصال غير كافية. أضف البريد الإلكتروني ورقم الهاتف وملف LinkedIn.")
            else:
                issues.append("Insufficient contact information. Add email, phone number, and LinkedIn profile.")
        
        # Return formatting analysis
        return {
            "score": formatting_score,
            "issues": issues
        }

    def analyze_content_quality(self, resume_text: str) -> Dict[str, Any]:
        """
        Analyze CV content quality.
        
        Args:
            resume_text: The extracted text from the resume
            
        Returns:
            Dictionary with content quality analysis results
        """
        # Initialize content quality score
        content_score = 0
        issues = []
        language = self.detect_language(resume_text)
        nlp = self.get_nlp_model(resume_text)
        doc = nlp(resume_text)
        
        # Check for action verbs (indicates achievement-oriented content)
        action_verbs = {
            'en': [
                'achieved', 'improved', 'developed', 'managed', 'created', 'implemented',
                'increased', 'decreased', 'negotiated', 'led', 'coordinated', 'designed',
                'launched', 'built', 'delivered', 'generated', 'reduced', 'resolved'
            ],
            'ar': [
                'حققت', 'طورت', 'أدرت', 'أنشأت', 'نفذت', 'زادت', 'قللت', 'تفاوضت',
                'قدت', 'نسقت', 'صممت', 'أطلقت', 'بنيت', 'سلمت', 'أنتجت', 'خفضت', 'حللت'
            ]
        }
        
        verbs = action_verbs['ar'] if language == 'ar' else action_verbs['en']
        action_verb_count = 0
        
        for verb in verbs:
            action_verb_count += len(re.findall(r'\b' + verb + r'\b', resume_text, re.IGNORECASE))
        
        # Calculate action verb score (max 30 points)
        verb_score = min(30, action_verb_count * 3)
        content_score += verb_score
        
        if action_verb_count < 5:
            if language == 'ar':
                issues.append("استخدم المزيد من الأفعال النشطة مثل 'حققت'، 'طورت'، 'أدرت' لإظهار إنجازاتك.")
            else:
                issues.append("Use more action verbs like 'achieved', 'developed', 'managed' to showcase your accomplishments.")
        
        # Check for quantifiable achievements
        number_pattern = r'\b\d+%?\b'
        numbers_found = len(re.findall(number_pattern, resume_text))
        
        # Calculate quantifiable achievements score (max 25 points)
        numbers_score = min(25, numbers_found * 5)
        content_score += numbers_score
        
        if numbers_found < 3:
            if language == 'ar':
                issues.append("أضف أرقاماً محددة لتوضيح إنجازاتك (مثل: زيادة المبيعات بنسبة 20%).")
            else:
                issues.append("Add specific numbers to quantify your achievements (e.g., increased sales by 20%).")
        
        # Check for technical terms and industry jargon
        technical_terms = self.extract_keywords(resume_text)
        technical_term_count = len(technical_terms)
        
        # Calculate technical terms score (max 25 points)
        technical_score = min(25, technical_term_count)
        content_score += technical_score
        
        if technical_term_count < 10:
            if language == 'ar':
                issues.append("أضف المزيد من المصطلحات التقنية والمهارات المتعلقة بمجالك.")
            else:
                issues.append("Add more technical terms and skills relevant to your field.")
        
        # Check for sentence length and variety (indicates good writing)
        sentences = [sent.text for sent in doc.sents]
        if len(sentences) > 0:
            avg_sentence_length = sum(len(sent.split()) for sent in sentences) / len(sentences)
            sentence_length_variety = len(set(len(sent.split()) for sent in sentences))
            
            # Calculate sentence quality score (max 20 points)
            sentence_score = 0
            if 8 <= avg_sentence_length <= 20:
                sentence_score += 10
            if sentence_length_variety >= 3:
                sentence_score += 10
            
            content_score += sentence_score
            
            if avg_sentence_length > 25:
                if language == 'ar':
                    issues.append("الجمل طويلة جداً. استخدم جملاً أقصر وأكثر تأثيراً.")
                else:
                    issues.append("Sentences are too long. Use shorter, more impactful sentences.")
            elif avg_sentence_length < 5:
                if language == 'ar':
                    issues.append("الجمل قصيرة جداً. قم بتطوير أفكارك بشكل أكثر اكتمالاً.")
                else:
                    issues.append("Sentences are too short. Develop your ideas more completely.")
        
        # Return content quality analysis
        return {
            "score": content_score,
            "issues": issues
        }

    def analyze_readability(self, resume_text: str) -> Dict[str, Any]:
        """
        Analyze CV readability.
        
        Args:
            resume_text: The extracted text from the resume
            
        Returns:
            Dictionary with readability analysis results
        """
        # Initialize readability score
        readability_score = 0
        issues = []
        language = self.detect_language(resume_text)
        
        # Check for text length (too short or too long)
        word_count = len(resume_text.split())
        
        # Calculate length score (max 25 points)
        length_score = 0
        if 300 <= word_count <= 700:
            length_score = 25
        elif 200 <= word_count < 300 or 700 < word_count <= 1000:
            length_score = 15
        else:
            length_score = 5
        
        readability_score += length_score
        
        if word_count < 200:
            if language == 'ar':
                issues.append("السيرة الذاتية قصيرة جداً. أضف المزيد من التفاصيل حول خبراتك ومهاراتك.")
            else:
                issues.append("CV is too short. Add more details about your experiences and skills.")
        elif word_count > 1000:
            if language == 'ar':
                issues.append("السيرة الذاتية طويلة جداً. اختصر المحتوى للتركيز على أهم المعلومات.")
            else:
                issues.append("CV is too long. Condense content to focus on the most important information.")
        
        # Check for consistent formatting
        lines = resume_text.split('\n')
        line_length_variation = 0
        prev_line_length = 0
        
        for i, line in enumerate(lines):
            if i > 0 and line.strip() and prev_line_length > 0:
                line_length_variation += abs(len(line) - prev_line_length)
            if line.strip():
                prev_line_length = len(line)
        
        avg_variation = line_length_variation / len(lines) if len(lines) > 0 else 0
        
        # Calculate consistency score (max 25 points)
        consistency_score = 25 if avg_variation < 30 else (15 if avg_variation < 50 else 5)
        readability_score += consistency_score
        
        if avg_variation >= 50:
            if language == 'ar':
                issues.append("تنسيق غير متناسق. استخدم أطوال سطور متشابهة للمحتوى المماثل.")
            else:
                issues.append("Inconsistent formatting. Use similar line lengths for similar content.")
        
        # Check for jargon and complex words
        complex_word_count = 0
        words = resume_text.split()
        
        for word in words:
            if len(word) > 12:  # Arbitrary threshold for complex words
                complex_word_count += 1
        
        complex_word_ratio = complex_word_count / len(words) if len(words) > 0 else 0
        
        # Calculate complexity score (max 25 points)
        complexity_score = 25 if complex_word_ratio < 0.05 else (15 if complex_word_ratio < 0.1 else 5)
        readability_score += complexity_score
        
        if complex_word_ratio >= 0.1:
            if language == 'ar':
                issues.append("استخدام مفرط للمصطلحات المعقدة. استخدم لغة أبسط وأكثر مباشرة.")
            else:
                issues.append("Excessive use of complex terms. Use simpler, more direct language.")
        
        # Check for passive voice
        passive_patterns = {
            'en': [
                r'\b(is|are|was|were|be|been|being)\s+\w+ed\b',
                r'\b(is|are|was|were|be|been|being)\s+\w+en\b'
            ],
            'ar': [
                r'\b(تم|يتم)\s+\w+',
                r'\b(كان|كانت|يكون)\s+\w+'
            ]
        }
        
        patterns = passive_patterns['ar'] if language == 'ar' else passive_patterns['en']
        passive_count = 0
        
        for pattern in patterns:
            passive_count += len(re.findall(pattern, resume_text))
        
        passive_ratio = passive_count / len(words) if len(words) > 0 else 0
        
        # Calculate active voice score (max 25 points)
        active_score = 25 if passive_ratio < 0.05 else (15 if passive_ratio < 0.1 else 5)
        readability_score += active_score
        
        if passive_ratio >= 0.1:
            if language == 'ar':
                issues.append("استخدام مفرط للصيغة المبنية للمجهول. استخدم الصيغة المبنية للمعلوم لإظهار مسؤوليتك.")
            else:
                issues.append("Excessive use of passive voice. Use active voice to show ownership of your achievements.")
        
        # Return readability analysis
        return {
            "score": readability_score,
            "issues": issues
        }

    def analyze_keyword_match(self, resume_text: str, job_description: str) -> Dict[str, Any]:
        """
        Analyze keyword match between resume and job description.
        
        Args:
            resume_text: The extracted text from the resume
            job_description: The job description text
            
        Returns:
            Dictionary with keyword match analysis results
        """
        # Extract keywords from both texts
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
        
        # Generate issues based on match percentage
        issues = []
        language = self.detect_language(resume_text)
        
        if match_percentage < 30:
            if language == 'ar':
                issues.append("تطابق منخفض جداً للكلمات الرئيسية. أضف المزيد من الكلمات الرئيسية من الوصف الوظيفي.")
            else:
                issues.append("Very low keyword match. Add more keywords from the job description.")
        elif match_percentage < 60:
            if language == 'ar':
                issues.append("تطابق متوسط للكلمات الرئيسية. حاول تضمين المزيد من المصطلحات المحددة من الوصف الوظيفي.")
            else:
                issues.append("Moderate keyword match. Try to include more specific terms from the job description.")
        
        # Return keyword match analysis
        return {
            "score": round(match_percentage),
            "matching_keywords": list(matching_keywords),
            "missing_keywords": list(missing_keywords),
            "issues": issues
        }

    def analyze_cv(self, resume_text: str, job_description: str = "") -> Dict[str, Any]:
        """
        Perform comprehensive CV analysis with multiple scoring dimensions.
        
        Args:
            resume_text: The extracted text from the resume
            job_description: The job description text (optional)
            
        Returns:
            Dictionary containing comprehensive analysis results
        """
        try:
            # Detect language
            language = self.detect_language(resume_text)
            
            # Initialize result structure
            result = {
                "id": f"analysis_{datetime.now().strftime('%Y%m%d%H%M%S')}",
                "language": language,
                "direction": "rtl" if language == 'ar' else "ltr",
                "analysis_date": datetime.now().isoformat(),
                "success": True
            }
            
            # Extract keywords from resume
            resume_keywords = self.extract_keywords(resume_text)
            result["keywords"] = resume_keywords
            
            # Analyze formatting
            formatting_analysis = self.analyze_cv_formatting(resume_text)
            
            # Analyze content quality
            content_analysis = self.analyze_content_quality(resume_text)
            
            # Analyze readability
            readability_analysis = self.analyze_readability(resume_text)
            
            # If job description is provided, analyze keyword match
            keyword_match_analysis = {"score": 0, "matching_keywords": [], "missing_keywords": [], "issues": []}
            if job_description:
                keyword_match_analysis = self.analyze_keyword_match(resume_text, job_description)
                result["job_description"] = job_description
            
            # Calculate overall score
            if job_description:
                # With job description, keyword match is more important
                overall_score = int(
                    0.35 * keyword_match_analysis["score"] +
                    0.25 * formatting_analysis["score"] +
                    0.25 * content_analysis["score"] +
                    0.15 * readability_analysis["score"]
                )
            else:
                # Without job description, focus more on content and formatting
                overall_score = int(
                    0.40 * formatting_analysis["score"] +
                    0.40 * content_analysis["score"] +
                    0.20 * readability_analysis["score"]
                )
            
            # Ensure score is between 0 and 100
            overall_score = max(0, min(100, overall_score))
            
            # Add scores to result
            result["score"] = overall_score
            
            # Generate summary based on overall score
            if language == 'ar':
                if overall_score >= 80:
                    result["summary"] = "سيرة ذاتية ممتازة مع تنسيق جيد ومحتوى قوي. " + \
                                       f"تم العثور على {len(resume_keywords)} كلمة رئيسية ذات صلة بالصناعة."
                elif overall_score >= 60:
                    result["summary"] = "سيرة ذاتية جيدة مع بعض المجالات التي تحتاج إلى تحسين. " + \
                                       f"تم العثور على {len(resume_keywords)} كلمة رئيسية ذات صلة بالصناعة."
                else:
                    result["summary"] = "سيرة ذاتية تحتاج إلى تحسينات كبيرة في التنسيق والمحتوى. " + \
                                       f"تم العثور على {len(resume_keywords)} كلمة رئيسية ذات صلة بالصناعة."
            else:
                if overall_score >= 80:
                    result["summary"] = f"Excellent CV with good formatting and strong content. " + \
                                       f"Contains {len(resume_keywords)} industry-relevant keywords."
                elif overall_score >= 60:
                    result["summary"] = f"Good CV with some areas for improvement. " + \
                                       f"Contains {len(resume_keywords)} industry-relevant keywords."
                else:
                    result["summary"] = f"CV needs significant improvements in formatting and content. " + \
                                       f"Contains {len(resume_keywords)} industry-relevant keywords."
            
            # Add detailed analysis components
            result["skills_comparison"] = {
                "match_percentage": keyword_match_analysis["score"],
                "matching_keywords": keyword_match_analysis["matching_keywords"],
                "missing_keywords": keyword_match_analysis["missing_keywords"]
            }
            
            # Compile all issues as recommendations
            recommendations = []
            recommendations.extend(formatting_analysis["issues"])
            recommendations.extend(content_analysis["issues"])
            recommendations.extend(readability_analysis["issues"])
            recommendations.extend(keyword_match_analysis["issues"])
            
            # Add more general recommendations if needed
            if len(recommendations) < 3:
                if language == 'ar':
                    general_recommendations = [
                        "قم بتخصيص سيرتك الذاتية لكل وظيفة تتقدم لها.",
                        "استخدم تنسيقاً نظيفاً وسهل القراءة.",
                        "ركز على إنجازاتك بدلاً من مجرد سرد المسؤوليات.",
                        "تأكد من خلو سيرتك الذاتية من الأخطاء الإملائية والنحوية.",
                        "استخدم الكلمات الرئيسية ذات الصلة بمجالك."
                    ]
                else:
                    general_recommendations = [
                        "Tailor your CV for each job you apply to.",
                        "Use clean, easy-to-read formatting.",
                        "Focus on achievements rather than just listing responsibilities.",
                        "Ensure your CV is free of spelling and grammatical errors.",
                        "Use keywords relevant to your field."
                    ]
                
                # Add random general recommendations until we have at least 3
                while len(recommendations) < 3 and general_recommendations:
                    recommendation = random.choice(general_recommendations)
                    recommendations.append(recommendation)
                    general_recommendations.remove(recommendation)
            
            result["recommendations"] = recommendations
            
            # Add placeholder data for education and experience comparison
            # In a real implementation, these would be generated by more sophisticated analysis
            if language == 'ar':
                result["education_comparison"] = [
                    "تم ذكر المؤهلات التعليمية بشكل واضح.",
                    "يمكن إضافة المزيد من التفاصيل حول المشاريع الأكاديمية ذات الصلة."
                ]
                result["experience_comparison"] = [
                    "تم توثيق الخبرة العملية بشكل جيد.",
                    "يمكن التركيز أكثر على الإنجازات القابلة للقياس في كل دور."
                ]
            else:
                result["education_comparison"] = [
                    "Educational qualifications are clearly mentioned.",
                    "Could add more details about relevant academic projects."
                ]
                result["experience_comparison"] = [
                    "Work experience is well documented.",
                    "Could focus more on measurable achievements in each role."
                ]
            
            # Add searchability issues
            if language == 'ar':
                result["searchability_issues"] = [
                    "تأكد من استخدام تنسيق قياسي يمكن قراءته بواسطة أنظمة تتبع المتقدمين.",
                    "تجنب استخدام الرسومات المعقدة أو الجداول التي قد لا يتم تحليلها بشكل صحيح."
                ]
            else:
                result["searchability_issues"] = [
                    "Ensure you use a standard format that can be read by ATS systems.",
                    "Avoid using complex graphics or tables that may not be parsed correctly."
                ]
            
            return result

        except Exception as e:
            logger.error(f"Enhanced CV analysis failed: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "language": self.detect_language(resume_text),
                "direction": "rtl" if self.detect_language(resume_text) == "ar" else "ltr"
            }
