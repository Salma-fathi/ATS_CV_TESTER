# Add to utils/job_matcher.py (new file)
import re
from collections import defaultdict

class JobMatcher:
    """Advanced job description matching and recommendation engine."""
    
    def __init__(self, nlp_model=None):
        """Initialize with optional spaCy model."""
        self.nlp = nlp_model
        self.required_skills = []
        self.preferred_skills = []
        self.education_reqs = []
        self.experience_reqs = []
    
    def parse_job_description(self, job_text):
        """Extract key components from job description."""
        # Extract required skills
        required_section = self._extract_section(job_text, 
            ["required skills", "requirements", "qualifications", "must have"])
        if required_section:
            self.required_skills = self._extract_list_items(required_section)
        
        # Extract preferred skills
        preferred_section = self._extract_section(job_text,
            ["preferred skills", "nice to have", "desired", "plus"])
        if preferred_section:
            self.preferred_skills = self._extract_list_items(preferred_section)
        
        # Extract education requirements
        education_section = self._extract_section(job_text,
            ["education", "degree", "academic"])
        if education_section:
            self.education_reqs = self._extract_list_items(education_section)
        
        # Extract experience requirements
        experience_section = self._extract_section(job_text,
            ["experience", "background", "history"])
        if experience_section:
            self.experience_reqs = self._extract_list_items(experience_section)
        
        return {
            "required_skills": self.required_skills,
            "preferred_skills": self.preferred_skills,
            "education_reqs": self.education_reqs,
            "experience_reqs": self.experience_reqs
        }
    
    def generate_tailored_recommendations(self, resume_text, parsed_job=None):
        """Generate tailored recommendations based on resume and job match."""
        recommendations = defaultdict(list)
        
        # If we have parsed job data
        if parsed_job or (self.required_skills or self.preferred_skills):
            job_data = parsed_job or {
                "required_skills": self.required_skills,
                "preferred_skills": self.preferred_skills,
                "education_reqs": self.education_reqs,
                "experience_reqs": self.experience_reqs
            }
            
            # Check for missing required skills
            missing_required = []
            for skill in job_data["required_skills"]:
                if skill.lower() not in resume_text.lower():
                    missing_required.append(skill)
            
            if missing_required:
                recommendations["skills"].append(
                    f"Add these missing required skills: {', '.join(missing_required)}"
                )
            
            # Check for missing preferred skills
            missing_preferred = []
            for skill in job_data["preferred_skills"]:
                if skill.lower() not in resume_text.lower():
                    missing_preferred.append(skill)
            
            if missing_preferred:
                recommendations["skills"].append(
                    f"Consider adding these preferred skills: {', '.join(missing_preferred[:3])}"
                )
            
            # Education recommendations
            for edu_req in job_data["education_reqs"]:
                if edu_req.lower() not in resume_text.lower():
                    recommendations["education"].append(
                        f"Highlight education that matches: {edu_req}"
                    )
            
            # Experience recommendations
            for exp_req in job_data["experience_reqs"]:
                if exp_req.lower() not in resume_text.lower():
                    recommendations["experience"].append(
                        f"Emphasize experience related to: {exp_req}"
                    )
        
        # General recommendations if specific ones are limited
        if len(recommendations["skills"]) == 0:
            recommendations["skills"].append(
                "Ensure your skills section clearly lists your technical and soft skills"
            )
        
        if len(recommendations["education"]) == 0:
            recommendations["education"].append(
                "Format your education section with degree, institution, and graduation year"
            )
        
        if len(recommendations["experience"]) == 0:
            recommendations["experience"].append(
                "Use action verbs and quantify achievements in your experience section"
            )
        
        return dict(recommendations)
    
    def _extract_section(self, text, section_keywords):
        """Extract a section from text based on keywords."""
        for keyword in section_keywords:
            pattern = re.compile(r'(?i)' + re.escape(keyword) + r'[:\s]+(.*?)(?:\n\s*\n|\Z)', re.DOTALL)
            match = pattern.search(text)
            if match:
                return match.group(1).strip()
        return ""
    
    def _extract_list_items(self, text):
        """Extract list items from text."""
        # Try to find bullet points or numbered lists
        items = re.findall(r'(?:^|\n)(?:\s*[-•*]\s*|\s*\d+\.\s*)(.+)', text)
        
        # If no bullet points found, try splitting by newlines
        if not items:
            items = [line.strip() for line in text.split('\n') if line.strip()]
        
        return items
