FROM ${{ values.baseImage }}

WORKDIR /app

# Copy application files
COPY . .

# Install dependencies based on the base image
{% if values.baseImage == "node:18-alpine" %}
# Node.js specific setup
RUN npm ci --only=production
EXPOSE ${{ values.port }}
CMD ["node", "index.js"]
{% endif %}

{% if values.baseImage == "python:3.11-alpine" %}
# Python specific setup
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE ${{ values.port }}
CMD ["python", "app.py"]
{% endif %}

{% if values.baseImage == "openjdk:17-alpine" %}
# Java specific setup
RUN ./gradlew build --no-daemon
EXPOSE ${{ values.port }}
CMD ["java", "-jar", "build/libs/app.jar"]
{% endif %}

{% if values.baseImage == "golang:1.20-alpine" %}
# Go specific setup
RUN go build -o main .
EXPOSE ${{ values.port }}
CMD ["./main"]
{% endif %}

{% if values.includeHealthcheck %}
# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${{ values.port }}/health || exit 1
{% endif %}
