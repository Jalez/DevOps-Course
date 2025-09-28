#!/usr/bin/env python3

import os
import time
import shutil
import requests
import psutil
from datetime import datetime
from flask import Flask, request, Response

app = Flask(__name__)

# Configuration
PEER_SERVICE_URL = os.getenv('SERVICE2_URL', 'http://service2:3000')
STORAGE_SERVICE_URL = os.getenv('STORAGE_URL', 'http://storage:5000')
VOLUME_STORAGE_PATH = '/app/vstorage/vstorage'

def create_error_response(error_message):
    """Create standardized error response"""
    return Response(f"Error: {str(error_message)}", status=500, mimetype='text/plain')

def make_http_request(method, url, **kwargs):
    """Generic HTTP request helper with error handling"""
    try:
        response = requests.request(method, url, **kwargs)
        response.raise_for_status()
        return response
    except Exception as e:
        print(f"HTTP request failed: {method} {url} - {e}")
        raise

def get_system_info():
    """Get system status information"""
    # Get uptime in hours
    uptime_seconds = time.time() - psutil.boot_time()
    uptime_hours = round(uptime_seconds / 3600, 2)

    # Get free disk space in MB
    disk_usage = shutil.disk_usage('/')
    free_disk_mb = round(disk_usage.free / (1024 * 1024), 2)

    # Create timestamp in ISO 8601 format
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

    return f"{timestamp}: uptime {uptime_hours} hours, free disk in root: {free_disk_mb} MBytes"

def persist_record(record):
    """Append record to volume storage"""
    try:
        with open(VOLUME_STORAGE_PATH, 'a') as f:
            f.write(record + '\n')
    except Exception as e:
        print(f"Error writing to volume storage: {e}")

def submit_record(record):
    """Send record to storage service"""
    try:
        make_http_request('POST', f"{STORAGE_SERVICE_URL}/log",
                         data=record,
                         headers={'Content-Type': 'text/plain'})
    except Exception as e:
        print(f"Error submitting to storage service: {e}")

@app.route('/status', methods=['GET'])
def status():
    """Handle /status endpoint"""
    try:
        # 1. Analyze local system status
        system_info = get_system_info()

        # 2. Submit record to storage service
        submit_record(system_info)

        # 3. Persist record to volume storage
        persist_record(system_info)

        # 4. Request peer service status
        peer_response = make_http_request('GET', f"{PEER_SERVICE_URL}/status")
        peer_info = peer_response.text.strip()

        # 5-8. Peer service operations are handled by peer service
        # 9. Combine and return response
        combined_response = f"{system_info}\n{peer_info}"

        return Response(combined_response, mimetype='text/plain')

    except Exception as e:
        return create_error_response(e)

@app.route('/log', methods=['GET'])
def log():
    """Handle /log endpoint"""
    try:
        # Forward request to storage service
        response = make_http_request('GET', f"{STORAGE_SERVICE_URL}/log")
        return Response(response.text, mimetype='text/plain')
    except Exception as e:
        return create_error_response(e)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return Response("OK", mimetype='text/plain')

if __name__ == '__main__':
    # Ensure volume storage file is fresh (start with empty file)
    os.makedirs(os.path.dirname(VOLUME_STORAGE_PATH), exist_ok=True)
    # Always start with a fresh file, similar to storage service
    with open(VOLUME_STORAGE_PATH, 'w') as f:
        f.write('')

    app.run(host='0.0.0.0', port=8199, debug=False)
