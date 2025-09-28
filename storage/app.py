#!/usr/bin/env python3

import os
from flask import Flask, request, Response

app = Flask(__name__)

# Configuration
LOG_FILE_PATH = '/app/vstorage/storage.log'

def ensure_log_file():
    """Ensure the log file exists and is fresh"""
    # Always start with a fresh log file (similar to vStorage handling)
    os.makedirs(os.path.dirname(LOG_FILE_PATH), exist_ok=True)
    with open(LOG_FILE_PATH, 'w') as f:
        f.write('')

@app.route('/log', methods=['POST'])
def append_log():
    """Append incoming record to the log file"""
    try:
        # Get the record from request body
        record = request.get_data(as_text=True)
        
        # Append to log file
        with open(LOG_FILE_PATH, 'a') as f:
            f.write(record + '\n')
        
        return Response("OK", status=200, mimetype='text/plain')
        
    except Exception as e:
        return Response(f"Error: {str(e)}", status=500, mimetype='text/plain')

@app.route('/log', methods=['GET'])
def get_log():
    """Get the content of the whole stored log"""
    try:
        if not os.path.exists(LOG_FILE_PATH):
            return Response("", mimetype='text/plain')
        
        with open(LOG_FILE_PATH, 'r') as f:
            content = f.read()
        
        return Response(content, mimetype='text/plain')
        
    except Exception as e:
        return Response(f"Error: {str(e)}", status=500, mimetype='text/plain')

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return Response("OK", mimetype='text/plain')

@app.route('/clear', methods=['POST'])
def clear_log():
    """Clear the log file (for testing/cleanup purposes)"""
    try:
        with open(LOG_FILE_PATH, 'w') as f:
            f.write('')
        return Response("Log cleared", status=200, mimetype='text/plain')
    except Exception as e:
        return Response(f"Error: {str(e)}", status=500, mimetype='text/plain')

if __name__ == '__main__':
    # Ensure log file exists
    ensure_log_file()
    
    app.run(host='0.0.0.0', port=5000, debug=False)
