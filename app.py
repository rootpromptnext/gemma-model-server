from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline
import torch
import os
from huggingface_hub import login

# Login using environment variable (preferred)
hf_token = os.getenv("HUGGINGFACE_HUB_TOKEN")
if hf_token:
    login(token=hf_token)

app = FastAPI(title="Gemma-2B Model Server")

device = 0 if torch.cuda.is_available() else -1

# Load Gemma-2B model (requires gated repo access)
model = pipeline(
    "text-generation",
    model="google/gemma-2b",
    device=device
)

class Request(BaseModel):
    message: str

@app.get("/")
def home():
    return {"status": "Gemma-2B Model Server Running"}

@app.post("/generate")
def generate(request: Request):
    result = model(request.message, max_length=100)
    return {"response": result[0]["generated_text"]}
