FROM python:3.12-slim

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Create storage directory
RUN mkdir -p /app

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
