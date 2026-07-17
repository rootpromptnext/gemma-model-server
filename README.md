# Gemma Model Server (GPU)

A FastAPI-based inference server for **Google Gemma-2B**, containerized with Docker and deployable on MicroK8s.  
This lab demonstrates end-to-end setup: VM provisioning, app development, containerization, and Kubernetes deployment.

---

## Prerequisites

- GCP VM with **NVIDIA T4 GPU** (Terraform config provided).
- Python 3.12 + `venv`.
- Hugging Face account with **Gemma-2B access**.
- Hugging Face token (`HUGGINGFACE_HUB_TOKEN`).
- Docker with NVIDIA runtime.
- MicroK8s with GPU plugin enabled.

---

## Hugging Face Authentication

Gemma-2B is a **gated model**. You must request access at:  
[https://huggingface.co/google/gemma-2b](https://huggingface.co/google/gemma-2b)

Once approved:

```bash
huggingface-cli login
# or
export HUGGINGFACE_HUB_TOKEN=hf_your_token_here
```

---

## 1. Local Development

### 1. Create virtual environment
```bash
sudo apt install -y python3.12-venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 2. Run FastAPI app
```bash
uvicorn app:app --host 0.0.0.0 --port 9000
```

### 3. Test with curl
```bash
curl -X POST http://localhost:9000/generate \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello Gemma, tell me a fun fact"}'
```

---

## Docker

### Dockerfile
```dockerfile
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py /app

EXPOSE 9000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "9000"]
```

### Build & Run
```bash
docker build -t gemma-model-server .
docker run --gpus all -e HUGGINGFACE_HUB_TOKEN=$HUGGINGFACE_HUB_TOKEN -p 9000:9000 gemma-model-server
```

### Test
```bash
curl -X POST http://localhost:9000/generate \
  -H "Content-Type: application/json" \
  -d '{"message":"Write a haiku about Kubernetes"}'
```

---

## K8s Deployment

### Deployment YAML
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gemma-model-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gemma-model-server
  template:
    metadata:
      labels:
        app: gemma-model-server
    spec:
      containers:
      - name: gemma-model-server
        image: gemma-model-server:latest
        ports:
        - containerPort: 9000
        env:
        - name: HUGGINGFACE_HUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: hf-secret
              key: token
        resources:
          limits:
            nvidia.com/gpu: 1
---
apiVersion: v1
kind: Service
metadata:
  name: gemma-model-server-service
spec:
  selector:
    app: gemma-model-server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 9000
  type: LoadBalancer
```

### Apply
```bash
microk8s kubectl apply -f k8s/deployment.yaml
microk8s kubectl get pods
microk8s kubectl get svc gemma-model-server-service
```

### Test
```bash
curl -X POST http://<LB-IP>/generate \
  -H "Content-Type: application/json" \
  -d '{"message":"Explain observability in simple terms"}'
```

---

## Recap

- **Terraform** → GPU VM with firewall (ports 22, 9000, 80, 443).  
- **FastAPI app** → Hugging Face Gemma‑2B pipeline.  
- **requirements.txt** → torch, transformers, fastapi, uvicorn, huggingface_hub.  
- **Dockerfile** → GPU‑enabled container.  
- **MicroK8s** → Deployment + LoadBalancer with GPU scheduling.  
- **Authentication** → Hugging Face token required for Gemma‑2B.

---

## Notes

- If you don’t yet have access to Gemma‑2B, swap in an open model like `distilgpt2` for testing.  
- Always pass `HUGGINGFACE_HUB_TOKEN` securely (env var, Kubernetes Secret).  
- For production, add TLS termination (port 443) via Ingress/NGINX.
