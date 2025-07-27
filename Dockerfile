FROM python:3.11-slim

WORKDIR /app

# Copy only requirements.txt first (for better caching)
COPY app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy rest of the application
COPY app/ .

# Expose the Flask port
EXPOSE 5000

# Run the app
CMD ["python", "main.py"]

