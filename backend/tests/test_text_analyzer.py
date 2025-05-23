# Add to tests/test_text_analyzer.py (new file)
import unittest
from utils.text_analyzer import TextAnalyzer

class TestTextAnalyzer(unittest.TestCase):
    """Test cases for TextAnalyzer class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.analyzer = TextAnalyzer()
        
        # Sample texts
        self.english_text = "I am a software engineer with 5 years of experience in Python and JavaScript."
        self.arabic_text = "أنا مهندس برمجيات لدي 5 سنوات من الخبرة في بايثون وجافا سكريبت."
        
    def test_detect_language_english(self):
        """Test language detection for English text."""
        language = self.analyzer.detect_language(self.english_text)
        self.assertEqual(language, 'en')
        
    def test_detect_language_arabic(self):
        """Test language detection for Arabic text."""
        language = self.analyzer.detect_language(self.arabic_text)
        self.assertEqual(language, 'ar')
        
    def test_extract_keywords_english(self):
        """Test keyword extraction for English text."""
        keywords = self.analyzer.extract_keywords(self.english_text)
        self.assertIn('software', keywords)
        self.assertIn('engineer', keywords)
        self.assertIn('python', keywords)
        self.assertIn('javascript', keywords)
        
    def test_analyze_text(self):
        """Test text analysis with job description."""
        resume = "I am a software engineer with experience in Python, JavaScript, and React."
        job = "Looking for a software engineer with Python and Django experience."
        
        result = self.analyzer.analyze_text(resume, job)
        
        self.assertTrue(result['success'])
        self.assertIn('software', result['skills_comparison']['matching_keywords'])
        self.assertIn('python', result['skills_comparison']['matching_keywords'])
        self.assertIn('django', result['skills_comparison']['missing_keywords'])
        
if __name__ == '__main__':
    unittest.main()
