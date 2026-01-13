FROM python:3.10-slim
WORKDIR /app
COPY inference.py .
RUN pip install --no-cache-dir transformers torch huggingface_hub
CMD ["python", "inference.py"]
