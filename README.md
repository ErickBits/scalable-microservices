# Scalable Microservices Deployment

A production-ready microservices architecture deployed on AWS EKS, using Terraform for infrastructure provisioning, Kubernetes for orchestration, and Nginx as an API Gateway.

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              AWS Cloud                   │
                        │                                          │
  Client Request        │   ┌──────────────────────────────────┐  │
  ─────────────────────►│   │        EKS Cluster               │  │
  GET /api/products     │   │                                  │  │
                        │   │  ┌─────────────────────────┐    │  │
                        │   │  │   Nginx API Gateway      │    │  │
                        │   │  │   (LoadBalancer :80)     │    │  │
                        │   │  └────────┬────────┬────────┘    │  │
                        │   │           │        │              │  │
                        │   │    /api/users  /api/products      │  │
                        │   │           │        │              │  │
                        │   │  ┌────────▼──┐ ┌───▼───────────┐ │  │
                        │   │  │  users-   │ │  products-    │ │  │
                        │   │  │  service  │ │  service      │ │  │
                        │   │  │  :3001    │ │  :3002        │ │  │
                        │   │  │  x2 pods  │ │  x2 pods      │ │  │
                        │   │  └─────┬─────┘ └──────┬────────┘ │  │
                        │   │        │               │          │  │
                        │   │        └──────┬────────┘          │  │
                        │   │               │                   │  │
                        │   │        ┌──────▼──────┐            │  │
                        │   │        │   MongoDB   │            │  │
                        │   │        │ StatefulSet │            │  │
                        │   │        └─────────────┘            │  │
                        │   └──────────────────────────────────┘  │
                        │                                          │
                        │   ECR (Docker Registry)                  │
                        │   VPC + Subnets + NAT Gateway            │
                        └─────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 20 + Express |
| Database | MongoDB 7 |
| API Gateway | Nginx 1.25 |
| Containers | Docker |
| Orchestration | Kubernetes (AWS EKS) |
| Infrastructure | Terraform |
| Container Registry | AWS ECR |
| CI/CD | GitHub Actions |
| Auto-scaling | Kubernetes HPA |

## Project Structure

```
scalable-microservices/
├── services/
│   ├── users-service/       # Auth microservice (register, login, JWT)
│   └── products-service/    # Products CRUD microservice
├── nginx/
│   └── nginx.conf           # API Gateway routing config
├── k8s/
│   ├── namespace.yaml
│   ├── users-service/       # Deployment, Service, HPA
│   ├── products-service/    # Deployment, Service, HPA
│   ├── nginx/               # Deployment, Service, ConfigMap
│   └── mongodb/             # StatefulSet, Service
├── terraform/
│   ├── main.tf              # Provider config
│   ├── vpc.tf               # VPC, subnets, NAT Gateway
│   ├── eks.tf               # EKS cluster + node group
│   ├── ecr.tf               # Docker registries
│   ├── variables.tf
│   └── outputs.tf
├── .github/workflows/
│   └── ci-cd.yml            # Test → Build → Push ECR → Deploy EKS
├── docker-compose.yml       # Local development
├── Makefile                 # Useful commands
└── .env.example
```

## API Endpoints

All requests go through Nginx on port 80.

### Users Service
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/users/register` | No | Register a new user |
| POST | `/api/users/login` | No | Login and get JWT token |
| GET | `/api/users/me` | Yes | Get current user profile |

### Products Service
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/products` | Yes | List all products |
| POST | `/api/products` | Yes | Create a product |
| GET | `/api/products/:id` | Yes | Get a product by ID |
| PUT | `/api/products/:id` | Yes | Update a product |
| DELETE | `/api/products/:id` | Yes | Delete a product |

### Health Checks
| Endpoint | Description |
|---|---|
| `/health` | Nginx gateway status |
| `/services/users/health` | users-service status |
| `/services/products/health` | products-service status |

**Auth header format:** `Authorization: Bearer <token>`

## Local Development

**Prerequisites:** Docker and Docker Compose installed.

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USER/scalable-microservices.git
cd scalable-microservices

# 2. Create environment file
cp .env.example .env
# Edit .env and set a strong JWT_SECRET

# 3. Start all services
make dev
# or: docker compose up --build

# 4. Test the API
curl http://localhost/health
curl -X POST http://localhost/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","password":"secret123"}'
```

## AWS Deployment

### 1. Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0
- kubectl installed

### 2. Provision infrastructure with Terraform

```bash
make tf-init    # Initialize Terraform
make tf-plan    # Preview what will be created
make tf-apply   # Create VPC, EKS cluster, ECR repos
```

After apply, Terraform outputs the ECR URLs. Update the image references in `k8s/*/deployment.yaml`.

### 3. Configure kubectl

```bash
make kubeconfig
# or: aws eks update-kubeconfig --region us-east-1 --name scalable-microservices
```

### 4. Create the JWT secret in Kubernetes

```bash
kubectl create secret generic app-secrets \
  --from-literal=jwt-secret=YOUR_STRONG_SECRET \
  -n microservices
```

### 5. Build and push Docker images

```bash
make build
make push-ecr AWS_ACCOUNT_ID=123456789012
```

### 6. Deploy to Kubernetes

```bash
make deploy-k8s
make status      # Check pods and services
```

### 7. Get the public URL

```bash
kubectl get svc nginx-gateway -n microservices
# Copy the EXTERNAL-IP value — that's your public URL
```

## CI/CD Pipeline

On every push to `main`, GitHub Actions automatically:

1. **Test** — runs tests for both services against a real MongoDB instance
2. **Build & Push** — builds Docker images and pushes them to AWS ECR tagged with the commit SHA
3. **Deploy** — updates the Kubernetes deployments with the new image and waits for rollout

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret key |

## Auto-scaling

Both services have a HorizontalPodAutoscaler configured:
- **Min replicas:** 2
- **Max replicas:** 6
- **Scale up trigger:** CPU usage > 70%

Kubernetes will automatically add or remove pods based on load.

## Destroying the infrastructure

```bash
make destroy-k8s   # Remove Kubernetes resources
make tf-destroy    # Destroy all AWS infrastructure (stops billing)
```

> **Note:** TLS/HTTPS support is planned as a future improvement. The current setup runs on HTTP port 80.

## License

MIT
