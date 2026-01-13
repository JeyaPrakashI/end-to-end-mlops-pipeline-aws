from transformers import pipeline

# Load model once at cold start
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased")

def lambda_handler(event, context):
    text = event.get("text", "")
    if not text:
        return {
            "statusCode": 400,
            "body": "Missing 'text' in event payload"
        }

    result = classifier(text)
    return {
        "statusCode": 200,
        "body": str(result)
    }
