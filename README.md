🚀 Amazon Prime Video Clone – CI/CD Pipeline on EKS with Monitoring

This project demonstrates a complete CI/CD pipeline for deploying a Node.js-based Amazon Prime Video clone application onto an Amazon EKS cluster.
The pipeline also provisions a monitoring stack using Prometheus, Grafana, and Blackbox Exporter via Terraform.

📑 Table of Contents

Prerequisites

Server Setup

Docker

Jenkins

Terraform

CI Pipeline – Build & Push Docker Image

Dockerfile

Jenkinsfile (CI)

EKS Setup

AWS CLI

eksctl

Create EKS Cluster

CD Pipeline – Deploy to EKS

Kubernetes Manifest

Jenkinsfile (CD)

Terraform – Monitoring Infrastructure

Prometheus & Grafana Setup

Prometheus Installation

Grafana Installation

Blackbox Exporter Configuration

Prometheus Configuration

Dashboards

Prometheus Dashboard

Grafana Blackbox Dashboard

Grafana Jenkins Dashboard

Project Architecture Diagram

Conclusion

🔧 Prerequisites

Ubuntu 20.04+ server (used as CI/CD runner and monitoring host)

AWS Account with IAM user (amazonprimevideo) and necessary policies

GitHub repository for application & Kubernetes manifests

Jenkins installed and configured

🖥️ Server Setup
1. Install Docker
sudo apt update -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker


Verify installation:

docker --version

2. Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins


Access Jenkins at:
👉 http://<your-server-ip>:8080

3. Install Terraform
sudo apt update -y
sudo apt install wget unzip -y
wget https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip
unzip terraform_1.9.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

⚙️ CI Pipeline
Dockerfile
FROM node:alpine

WORKDIR /app

COPY package.json package-lock.json /app/
RUN npm install

COPY . /app/

EXPOSE 3000
CMD ["npm","start"]

Jenkinsfile (CI)

This pipeline builds the Docker image and pushes it to Docker Hub.

pipeline {
    agent any

    stages {
        stage('Clean WS') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout'){
            steps{
                git branch:'main',url: 'https://github.com/nrjydv1997/amazon-prime-video-kubernetes.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t nrjydv1997/amazon-prime-video .
                docker push nrjydv1997/amazon-prime-video
                '''
            }
        }
    }
}

☸️ EKS Setup
1. Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version

2. Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

3. Create EKS Cluster
eksctl create cluster --name=nrjydv \
  --region=ap-south-1 \
  --zones=ap-south-1a,ap-south-1b \
  --version=1.30 \
  --without-nodegroup

🚀 CD Pipeline
Kubernetes Manifest (manifest.yaml)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: amazon-prime-video-deployment
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: amazon-prime-video
  template:
    metadata:
      labels:
        app: amazon-prime-video
    spec:
      containers:
        - name: amazon-prime-video-container
          image: nrjydv1997/amazon-prime-video
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: amazon-prime-video-service
spec:
  type: LoadBalancer
  selector:
    app: amazon-prime-video
  ports:
    - port: 80
      targetPort: 3000

Jenkinsfile (CD)
pipeline {
    agent any

    stages {
        stage('Clean WS') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout'){
            steps{
                git branch:'main',url: 'https://github.com/nrjydv1997/amazon-prime-video-kubernetes.git'
            }
        }
        
        stage('Deploy to EKS'){
            steps{
                dir('kubernetes'){
                    script{
                        sh '''
                        echo "Verifying AWS credentials..."
                        aws sts get-caller-identity
                        
                        echo "Configure kubectl for eks cluster..."
                        aws eks update-kubeconfig --region ap-south-1 --name nrjydv
                        
                        echo "Deploying application to EKS"
                        kubectl apply -f manifest.yaml
                        
                        kubectl get pods
                        kubectl get svc
                        '''
                    }
                }
            }
        }
    }
}

📊 Terraform – Monitoring

A Terraform resource was created to provision a monitoring server (EC2).
The Jenkins pipeline executed terraform init, plan, and apply.

📡 Prometheus & Grafana Setup
Install Prometheus
# Run installation script (snippet shown)
wget https://github.com/prometheus/prometheus/releases/download/v2.51.2/prometheus-2.51.2.linux-amd64.tar.gz
tar -xvzf prometheus-2.51.2.linux-amd64.tar.gz
sudo mv prometheus-2.51.2.linux-amd64 /etc/prometheus
...
sudo systemctl start prometheus

Install Grafana
sudo apt-get install -y apt-transport-https software-properties-common wget
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update -y
sudo apt-get install grafana -y
sudo systemctl start grafana-server
sudo systemctl enable grafana-server


Access Grafana: 👉 http://<server-ip>:3000 (default admin/admin)

Install Blackbox Exporter
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz
tar -xvzf blackbox_exporter-0.25.0.linux-amd64.tar.gz
./blackbox_exporter --config.file=blackbox.yml

Prometheus Configuration (prometheus.yml)
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://prometheus.io
          - http://13.233.196.205:3000
          - http://app.giftzmania.shop
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 65.2.126.181:9115

  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets:
          - '13.233.196.205:8080'