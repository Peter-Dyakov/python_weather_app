# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt (we will create this file next)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose the port Flask runs on
EXPOSE 5000

# Define the environment variable for Flask
ENV FLASK_ENV=development

# Command to run the app
CMD ["flask", "run", "--host=0.0.0.0"]
