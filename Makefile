.PHONY: help dev dev-down build push-ecr deploy-k8s destroy-k8s tf-init tf-plan tf-apply tf-destroy

# Variables — cámbialas por los tuyos antes de usar
AWS_REGION     ?= us-east-1
AWS_ACCOUNT_ID ?= 123456789012
CLUSTER_NAME   ?= scalable-microservices

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Desarrollo local ──────────────────────────────────────────────────────────

dev: ## Levanta todos los servicios localmente con Docker Compose
	cp -n .env.example .env || true
	docker compose up --build

dev-down: ## Para y elimina los contenedores locales
	docker compose down -v

# ── Docker / ECR ─────────────────────────────────────────────────────────────

build: ## Construye las imágenes Docker de ambos servicios
	docker build -t users-service:latest ./services/users-service
	docker build -t products-service:latest ./services/products-service

push-ecr: ## Sube las imágenes a AWS ECR
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	docker tag users-service:latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/users-service:latest
	docker tag products-service:latest $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/products-service:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/users-service:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/products-service:latest

# ── Kubernetes ────────────────────────────────────────────────────────────────

kubeconfig: ## Configura kubectl para apuntar al cluster EKS
	aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME)

deploy-k8s: ## Despliega todos los manifiestos en Kubernetes
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/mongodb/
	kubectl apply -f k8s/users-service/
	kubectl apply -f k8s/products-service/
	kubectl apply -f k8s/nginx/

destroy-k8s: ## Elimina todos los recursos de Kubernetes
	kubectl delete -f k8s/nginx/
	kubectl delete -f k8s/products-service/
	kubectl delete -f k8s/users-service/
	kubectl delete -f k8s/mongodb/
	kubectl delete -f k8s/namespace.yaml

status: ## Muestra el estado de los pods y servicios
	kubectl get pods,svc,hpa -n microservices

# ── Terraform ─────────────────────────────────────────────────────────────────

tf-init: ## Inicializa Terraform (primera vez)
	cd terraform && terraform init

tf-plan: ## Muestra qué va a crear/cambiar Terraform sin ejecutar nada
	cd terraform && terraform plan

tf-apply: ## Crea la infraestructura en AWS
	cd terraform && terraform apply

tf-destroy: ## DESTRUYE toda la infraestructura en AWS (cuidado: cobra dinero)
	cd terraform && terraform destroy
