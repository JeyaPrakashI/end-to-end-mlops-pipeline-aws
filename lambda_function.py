import json
from transformers import pipeline

# Load model once at cold start
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

def lambda_handler(event, context):
    # API Gateway sends body as a string
    body = event.get("body", "{}")
    try:
        data = json.loads(body)
    except:
        data = {}

    text = data.get("text", "")
    if not text:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing 'text' in request"})
        }

    result = classifier(text)
    return {
        "statusCode": 200,
        "body": json.dumps(result)
    }
