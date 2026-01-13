FROM public.ecr.aws/lambda/python:3.9

# Install Hugging Face + Torch
RUN pip install --no-cache-dir transformers torch

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the handler (file.function)
CMD ["lambda_function.lambda_handler"]
