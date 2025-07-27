**complete AKS Python App Project** with:

✅ Production-ready folder structure
✅ AKS infrastructure via Terraform
✅ Kubernetes deployment and LoadBalancer
✅ Dockerfile
✅ GitHub Actions CI/CD
✅ README and automation scripts

---

### 📁 Project Tree Overview

```
aks-python-app/
├── app/
│   ├── main.py
│   ├── requirements.txt
│   └── templates/
│       └── index.html
├── Dockerfile
├── .dockerignore
├── .gitignore
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── .github/
│   └── workflows/
│       └── deploy.yaml
├── scripts/
│   ├── build.sh
│   ├── deploy.sh
│   └── test.sh
├── LICENSE
└── README.md
```

---

## 🔧 Step-by-Step Code

---

### 🐍 `app/main.py`

```python
from flask import Flask, render_template
app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

---

### 📦 `app/requirements.txt`

```
Flask==2.2.5
```

---

### 🖼️ `app/templates/index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>Inventory App</title>
</head>
<body>
    <h1>Welcome to the AKS Inventory App 🚀</h1>
</body>
</html>
```

---

### 🐳 `Dockerfile`

```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY app/ /app/
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python", "main.py"]
```

---

### 📁 `terraform/main.tf`

```hcl
provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "inventory"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
```

---

### 📁 `terraform/variables.tf`

```hcl
variable "resource_group_name" {
  default = "rg-aks-inventory"
}

variable "location" {
  default = "East US"
}

variable "cluster_name" {
  default = "aks-inventory-cluster"
}
```

---

### 📁 `terraform/outputs.tf`

```hcl
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
```

---

### 📁 `terraform/backend.tf` (optional)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateacct123"
    container_name       = "tfstate"
    key                  = "aks-inventory.tfstate"
  }
}
```

---

### ☸️ `kubernetes/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-deployment
  labels:
    app: inventory
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
        image: atulkamble.azurecr.io/aks-python-app
        ports:
        - containerPort: 5000
```

---

### ☸️ `kubernetes/service.yaml`

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
    - name: http
      port: 80
      targetPort: 5000
```

---

### ☸️ `kubernetes/kustomization.yaml`

```yaml
resources:
  - deployment.yaml
  - service.yaml

images:
  - name: atulkamble.azurecr.io/aks-python-app
    newTag: latest
```

---

### 🤖 `.github/workflows/deploy.yaml`

```yaml
name: Build and Deploy to AKS

on:
  push:
    branches:
      - main

env:
  IMAGE_NAME: aks-python-app

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Get AKS Credentials
      run: |
        az aks get-credentials --name ${{ secrets.AKS_CLUSTER_NAME }} \
          --resource-group ${{ secrets.RESOURCE_GROUP }} --overwrite-existing

    - name: Docker Login to ACR
      uses: docker/login-action@v3
      with:
        registry: ${{ secrets.ACR_LOGIN_SERVER }}
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}

    - name: Build and Push Docker Image
      run: |
        docker build -t ${{ secrets.ACR_LOGIN_SERVER }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
        docker push ${{ secrets.ACR_LOGIN_SERVER }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

    - name: Update Image Tag in Kustomize
      run: |
        sed -i "s/newTag: .*/newTag: ${GITHUB_SHA}/" kubernetes/kustomization.yaml

    - name: Deploy to AKS
      run: |
        kubectl apply -k kubernetes/

    - name: Get External IP
      run: |
        kubectl get svc inventory-service
```

---

### 🛠️ `scripts/build.sh`

```bash
#!/bin/bash
docker build -t inventory-app:local ./app
```

### 🛠️ `scripts/deploy.sh`

```bash
#!/bin/bash
kubectl apply -k kubernetes/
```

### 🛠️ `scripts/test.sh`

```bash
#!/bin/bash
curl http://$(kubectl get svc inventory-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

---

### 📄 `.gitignore`

```
__pycache__/
*.pyc
.env
.terraform/
*.tfstate
*.tfstate.backup
kubeconfig
```

---

### 📘 `README.md`

````markdown
# AKS Python Inventory App

## 🌟 Overview

A simple Flask app deployed to Azure Kubernetes Service (AKS) with CI/CD and Infrastructure as Code (Terraform).

## 🚀 Features

- Python Flask Web App
- Dockerized
- AKS Cluster with LoadBalancer
- Terraform Infra
- GitHub Actions CI/CD

## 🛠️ Stack

- Python + Flask
- Docker
- Kubernetes (AKS)
- Terraform
- GitHub Actions

## 📦 Build and Run Locally

```bash
cd app
pip install -r requirements.txt
python main.py
````

## ☁️ Terraform Deployment

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

## ☸️ Kubernetes Deployment

```bash
kubectl apply -k kubernetes/
```

## 🤖 CI/CD

Push to `main` → GitHub Actions → Deploys to AKS

## 🔗 Access

After deployment:

```bash
kubectl get svc inventory-service
```

Open browser: `http://<EXTERNAL-IP>`

---

## Commands

```
az login --tenant cd62340f-1fff-4e1b-9527-7f7b1ab0fdc6

1

az account show

# Build with a tag
docker build -t atulkamble.azurecr.io/aks-python-app:latest .

# Login to ACR
az acr login --name atulkamble

# Push to ACR
docker push atulkamble.azurecr.io/aks-python-app:latest


az acr create \
  --resource-group rg-aks-inventory \
  --name atulkamble \
  --sku Basic \
  --location eastus

az aks update \
  --name aks-inventory-cluster \
  --resource-group rg-aks-inventory \
  --attach-acr atulkamble

az acr update -n atulkamble --admin-enabled true

kubectl create secret docker-registry acr-secret \
  --docker-server=atulkamble.azurecr.io \
  --docker-username="$(az acr credential show -n atulkamble --query 'username' -o tsv)" \
  --docker-password="$(az acr credential show -n atulkamble --query 'passwords[0].value' -o tsv)"


az acr list --query "[].{name:name, resourceGroup:resourceGroup}" -o table

// docker desktop in running 

az acr login --name atulkamble

docker build -t atulkamble.azurecr.io/aks-python-app .
docker push atulkamble.azurecr.io/aks-python-app

docker buildx build --platform linux/amd64 -t atuljkamble/inventory-app:latest --push .

docker buildx build --platform linux/amd64 -t atuljkamble/inventory-app:latest --push .

kubectl get pods

az aks get-credentials \
  --resource-group rg-aks-inventory \
  --name aks-inventory-cluster \
  --overwrite-existing

kubectl apply -f Kubernetes/deployment.yaml
kubectl apply -f Kubernetes/service.yaml

kubectl describe svc inventory-service

kubectl get svc inventory-service -w

EXTERNAL_IP=$(kubectl get svc inventory-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $EXTERNAL_IP
curl http://$EXTERNAL_IP

kubectl delete svc inventory-service
kubectl apply -f Kubernetes/service.yaml

kubectl delete pods --all
kubectl rollout restart deployment inventory-deployment

kubectl get nodes
kubectl get pods
kubectl get svc
kubectl get svc inventory-service -w
```

---


## working fine 

```
// keep docker desktop >> running 
// install git 

az login 

git clone https://github.com/atulkamble/aks-python-app.git
cd aks-python-app
ls

powershell >> run as admin 
winget install kubernetes.kubectl

docker login
docker build -t atuljkamble/inventory-app .

docker buildx build --platform linux/amd64 -t atuljkamble/inventory-app:latest

docker push atuljkamble/inventory-app:latest

docker run -d -p 5000:5000 atuljkamble/inventory-app

check url from browser >> http://localhost:5000/

sudo docker container ls

sudo docker container stop 3ba110aaef45

docker ps -a

// create aks cluster
2 nodes min 
3 nodes max 
Node sizes: Standard_DC2s_v2

az account set --subscription cc57cd42-dede-4674-b810-a0fbde41504a

az aks get-credentials --resource-group k8s --name newcluster --overwrite-existing

kubectl apply -f Kubernetes/deplyment.yaml
kubectl apply -f Kubernetes/service.yaml

kubectl get svc

// note down external ip and paste in browser 

// deploy aks using terraform 

cd terraform 

terraform init 
terraform plan 
terraform apply 
terraform destroy 


```
