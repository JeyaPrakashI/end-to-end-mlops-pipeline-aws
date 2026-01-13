FROM public.ecr.aws/lambda/python:3.10

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy handler
COPY lambda_function.py .

# Set Lambda entrypoint
CMD ["lambda_function.lambda_handler"]
