from transformers import AutoModelForSequenceClassification, AutoTokenizer, TrainingArguments, Trainer, EvalPrediction
from datasets import load_dataset
from peft import get_peft_model, LoraConfig, TaskType
import numpy as np
import json

# --- Model + Tokenizer ---
model_name = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=2)

# --- LoRA Config ---
config = LoraConfig(
    task_type=TaskType.SEQ_CLS,
    r=8,
    lora_alpha=32,
    lora_dropout=0.1,
    target_modules=["q_lin", "v_lin"]  # correct modules for DistilBERT
)
model = get_peft_model(model, config)

# --- Dataset ---
dataset = load_dataset("imdb")

def tokenize_function(example):
    return tokenizer(example["text"], padding="max_length", truncation=True)

tokenized_dataset = dataset.map(tokenize_function, batched=True)
tokenized_dataset = tokenized_dataset.rename_column("label", "labels")
tokenized_dataset.set_format(type="torch", columns=["input_ids", "attention_mask", "labels"])

# --- Training Arguments ---
training_args = TrainingArguments(
    output_dir="./results",
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=2,  # CI/CD run uses 2 epochs
    learning_rate=2e-5,
    weight_decay=0.01,
    evaluation_strategy="epoch",
    save_strategy="epoch",
    logging_dir="./logs",
    logging_steps=100,
    report_to="none"   # avoids interactive prompt
)

def compute_metrics(eval_pred: EvalPrediction):
    logits, labels = eval_pred
    predictions = np.argmax(logits, axis=-1)
    return {"accuracy": (predictions == labels).mean()}

# --- Trainer ---
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_dataset["train"].shuffle(seed=42).select(range(5000)),
    eval_dataset=tokenized_dataset["test"].shuffle(seed=42).select(range(1000)),
    compute_metrics=compute_metrics
)

# --- Train + Evaluate ---
trainer.train()
results = trainer.evaluate()
print("Evaluation results:", results)

# --- Save results.json for CI/CD accuracy gate ---
with open("results.json", "w") as f:
    json.dump(results, f)

# --- Save locally for push_to_hub.py ---
trainer.save_model("./results")
tokenizer.save_pretrained("./results")
