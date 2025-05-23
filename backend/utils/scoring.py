# Add to utils/scoring.py (new file)
class ResumeScorer:
    """Handles multi-dimensional resume scoring with category breakdowns."""
    
    CATEGORY_WEIGHTS = {
        "content": 0.35,
        "format": 0.20,
        "sections": 0.15,
        "style": 0.15,
        "skills": 0.15
    }
    
    def __init__(self):
        self.scores = {
            "content": 0,
            "format": 0,
            "sections": 0,
            "style": 0,
            "skills": 0,
            "overall": 0
        }
        self.issues = {
            "content": [],
            "format": [],
            "sections": [],
            "style": [],
            "skills": []
        }
    
    def calculate_overall_score(self):
        """Calculate weighted overall score."""
        weighted_sum = 0
        for category, score in self.scores.items():
            if category != "overall":
                weighted_sum += score * self.CATEGORY_WEIGHTS.get(category, 0)
        
        self.scores["overall"] = round(weighted_sum, 1)
        return self.scores["overall"]
    
    def add_issue(self, category, issue):
        """Add an issue to a specific category."""
        if category in self.issues:
            self.issues[category].append(issue)
            
    def get_issue_count(self):
        """Get total number of issues."""
        return sum(len(issues) for issues in self.issues.values())
