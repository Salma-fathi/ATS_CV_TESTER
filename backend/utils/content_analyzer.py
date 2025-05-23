# Add to utils/content_analyzer.py (new file)
import re
import spacy
from collections import Counter

class ContentAnalyzer:
    """Analyzes resume content quality beyond keywords."""
    
    # Common buzzwords and cliches to detect
    BUZZWORDS = [
        "team player", "detail-oriented", "self-starter", "go-getter",
        "think outside the box", "synergy", "results-driven", "proactive",
        "dynamic", "strategic thinker", "proven track record"
    ]
    
    def __init__(self, nlp_model=None):
        """Initialize with optional spaCy model."""
        self.nlp = nlp_model
    
    def find_repetitive_phrases(self, text, min_length=3, threshold=2):
        """Identify repetitive phrases in text."""
        if not self.nlp:
            return []
            
        doc = self.nlp(text)
        sentences = [sent.text for sent in doc.sents]
        
        # Extract phrases (3+ words)
        phrases = []
        for sentence in sentences:
            words = sentence.split()
            for i in range(len(words) - min_length + 1):
                phrase = " ".join(words[i:i+min_length])
                phrases.append(phrase.lower())
        
        # Count occurrences
        phrase_counter = Counter(phrases)
        repetitive = [phrase for phrase, count in phrase_counter.items() 
                     if count >= threshold]
        
        return repetitive
    
    def detect_buzzwords(self, text):
        """Detect common resume buzzwords and cliches."""
        found_buzzwords = []
        for buzzword in self.BUZZWORDS:
            if re.search(r'\b' + re.escape(buzzword) + r'\b', text.lower()):
                found_buzzwords.append(buzzword)
        
        return found_buzzwords
    
    def analyze_bullet_strength(self, bullet_points):
        """Analyze strength of bullet points based on action verbs and metrics."""
        strong_bullets = []
        weak_bullets = []
        
        for bullet in bullet_points:
            # Check for metrics (numbers, percentages)
            has_metrics = bool(re.search(r'\d+%|\$\d+|\d+\s*[kKmMbB]?', bullet))
            
            # Check for action verbs at beginning
            starts_with_action = bool(re.match(r'^(Achieved|Led|Created|Developed|Implemented|Increased|Reduced|Managed|Designed|Launched)', bullet))
            
            if has_metrics and starts_with_action:
                strong_bullets.append(bullet)
            else:
                weak_bullets.append(bullet)
        
        return {
            "strong_bullets": strong_bullets,
            "weak_bullets": weak_bullets,
            "improvement_needed": len(weak_bullets) > len(strong_bullets)
        }
