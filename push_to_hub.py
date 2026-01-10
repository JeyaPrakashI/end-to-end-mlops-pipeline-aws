from transformers import AutoTokenizer, AutoModelForSequenceClassification

# Load from results folder
model = AutoModelForSequenceClassification.from_pretrained("./results")
tokenizer = AutoTokenizer.from_pretrained("./results")

# Push to Hugging Face Hub (CI/CD version)
model.push_to_hub("JeyaPrakashI/distilbert-mlops-demo-ci")
tokenizer.push_to_hub("JeyaPrakashI/distilbert-mlops-demo-ci")
