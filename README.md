a **simple app** (Python Flask) that you can **containerize and deploy to Azure Kubernetes Service (AKS)** using Terraform, Docker, and `kubectl`.

---

## 🛠️ Step-by-Step AKS App Deployment Project

### ✅ 1. **Sample App Code** (`inventory-app`)

```
inventory-app/
├── app/
│   ├── main.py
│   ├── requirements.txt
│   └── templates/
│       └── index.html
├── Dockerfile
├── kubernetes/
│   ├── deployment.yaml
│   └── service.yaml
```

---

### 📄 `main.py`

```python
from flask import Flask, render_template
app = Flask(__name__)

@app.route('/')
def home():
    return render_template("index.html", title="Inventory Manager")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

---

### 📄 `requirements.txt`

```
Flask==2.3.2
```

---

### 📄 `templates/index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
</head>
<body>
    <h1>Welcome to {{ title }}!</h1>
</body>
</html>
```

---

### 📄 `Dockerfile`

```Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY app/ /app

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["python", "main.py"]
```

---

### 📄 `kubernetes/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: inventory
  template:
    metadata:
      labels:
        app: inventory
    spec:
      containers:
      - name: inventory-container
        image: atuljkamble/inventory:latest  # Update this to your DockerHub or ACR image
        ports:
        - containerPort: 5000
```

---

### 📄 `kubernetes/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: inventory-service
spec:
  type: LoadBalancer
  selector:
    app: inventory
  ports:
    - port: 80
      targetPort: 5000
```

---

## 🚀 2. **Build and Push Docker Image**

```bash
docker build -t atuljkamble/inventory:latest .
docker push atuljkamble/inventory:latest
```

---

## ☁️ 3. **Deploy to AKS**

Once your AKS cluster is created:

```bash
az aks get-credentials --resource-group aks-rg --name aks-cluster

kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

kubectl get svc inventory-service
```

You’ll get an **external IP** to access the app.

---

## ✅ Example Access

```
http://<external-ip>
```

---
