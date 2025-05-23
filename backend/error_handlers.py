# Add to error_handlers.py (new file)
from flask import Blueprint, jsonify, request, current_app
import logging
import traceback
import uuid
from werkzeug.exceptions import HTTPException

error_bp = Blueprint('errors', __name__)

class APIError(Exception):
    """Base class for API errors."""
    def __init__(self, message, status_code=400, payload=None):
        super().__init__()
        self.message = message
        self.status_code = status_code
        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        rv['error'] = self.message
        rv['status_code'] = self.status_code
        return rv

class ValidationError(APIError):
    """Validation error."""
    def __init__(self, message, payload=None):
        super().__init__(message, 400, payload)

class ResourceNotFoundError(APIError):
    """Resource not found error."""
    def __init__(self, message, payload=None):
        super().__init__(message, 404, payload)

class AuthenticationError(APIError):
    """Authentication error."""
    def __init__(self, message, payload=None):
        super().__init__(message, 401, payload)

@error_bp.app_errorhandler(APIError)
def handle_api_error(error):
    """Handle custom API errors."""
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    
    # Log the error
    current_app.logger.error(
        f"API Error: {error.message}",
        extra={
            'request_id': request.headers.get('X-Request-ID', str(uuid.uuid4())),
            'status_code': error.status_code
        }
    )
    
    return response

@error_bp.app_errorhandler(HTTPException)
def handle_http_error(error ):
    """Handle HTTP exceptions."""
    response = jsonify({
        'error': error.description,
        'status_code': error.code
    })
    response.status_code = error.code
    
    # Log the error
    current_app.logger.error(
        f"HTTP Error: {error.description}",
        extra={
            'request_id': request.headers.get('X-Request-ID', str(uuid.uuid4())),
            'status_code': error.code
        }
    )
    
    return response

@error_bp.app_errorhandler(Exception)
def handle_generic_error(error):
    """Handle generic exceptions."""
    # Generate unique error ID for tracking
    error_id = str(uuid.uuid4())
    
    # Log the full error with traceback
    current_app.logger.error(
        f"Unhandled Exception: {str(error)}",
        extra={
            'error_id': error_id,
            'request_id': request.headers.get('X-Request-ID', str(uuid.uuid4())),
            'traceback': traceback.format_exc()
        }
    )
    
    # Return generic error to client with ID for support
    response = jsonify({
        'error': 'An unexpected error occurred',
        'error_id': error_id,
        'status_code': 500
    })
    response.status_code = 500
    
    return response
