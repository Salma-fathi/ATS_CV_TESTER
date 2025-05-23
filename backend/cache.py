# Add to cache.py (new file)
from flask_caching import Cache
import json
import hashlib

cache = Cache()

def get_cache_key(prefix, data):
    """Generate a cache key from data."""
    data_str = json.dumps(data, sort_keys=True)
    return f"{prefix}:{hashlib.md5(data_str.encode()).hexdigest()}"

def cache_analysis_result(analysis_id, result, timeout=3600):
    """Cache an analysis result."""
    cache.set(f"analysis:{analysis_id}", result, timeout=timeout)

def get_cached_analysis(analysis_id):
    """Get a cached analysis result."""
    return cache.get(f"analysis:{analysis_id}")

def invalidate_analysis_cache(analysis_id):
    """Invalidate a cached analysis result."""
    cache.delete(f"analysis:{analysis_id}")
