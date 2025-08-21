# Use an official lightweight Python image as the base
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Expose port 5000 so the Flask app can be reached
EXPOSE 5000

# ARG is a build-time variable. Our pipeline will provide this.
ARG APP_AUTHOR="Local Dev"
# ENV sets the environment variable inside the final running container.
ENV APP_AUTHOR=$APP_AUTHOR

# The command to run the application
CMD ["flask", "run", "--host=0.0.0.0"]