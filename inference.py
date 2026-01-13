from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

model_name = "JeyaPrakashI/distilbert-mlops-demo-ci"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name)

def predict(text: str):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    outputs = model(**inputs)
    probs = torch.nn.functional.softmax(outputs.logits, dim=-1)
    return probs.detach().numpy()

if __name__ == "__main__":
    sample = "This movie was fantastic!"
    print("Prediction:", predict(sample))
