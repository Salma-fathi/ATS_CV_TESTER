# Add to models.py (new file)
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import uuid

db = SQLAlchemy()

class User(db.Model):
    """User model for authentication and result tracking."""
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    analyses = db.relationship('Analysis', backref='user', lazy=True)
    
    def __repr__(self):
        return f'<User {self.email}>'

class Resume(db.Model):
    """Resume model for storing uploaded resume data."""
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    filename = db.Column(db.String(255), nullable=False)
    content_hash = db.Column(db.String(64), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    analyses = db.relationship('Analysis', backref='resume', lazy=True)
    
    def __repr__(self):
        return f'<Resume {self.filename}>'

class Analysis(db.Model):
    """Analysis model for storing resume analysis results."""
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=True)
    resume_id = db.Column(db.String(36), db.ForeignKey('resume.id'), nullable=False)
    job_description = db.Column(db.Text, nullable=True)
    score = db.Column(db.Float, nullable=False)
    content_score = db.Column(db.Float, nullable=True)
    format_score = db.Column(db.Float, nullable=True)
    sections_score = db.Column(db.Float, nullable=True)
    style_score = db.Column(db.Float, nullable=True)
    skills_score = db.Column(db.Float, nullable=True)
    parse_rate = db.Column(db.Float, nullable=True)
    language = db.Column(db.String(5), nullable=False, default='en')
    results = db.Column(db.JSON, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Analysis {self.id}>'
