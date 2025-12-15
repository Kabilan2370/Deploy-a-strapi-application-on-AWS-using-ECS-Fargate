# 🚀 Getting started with Strapi

### strapi projects foler and files structure

    my-strapi-app/
    │
    ├── Dockerfile
    ├── .dockerignore
    ├── package.json
    ├── package-lock.json
    ├── README.md
    │
    ├── config/                 
    ├── src/                    # Strapi source files
    ├── public/
    │
    ├── .github/
    │   └── workflows/
    │       ├── ci.yml          # CI: Build & push Docker image workflow
    │       └── terraform.yml   # CD: Manual Terraform apply
    │
    └── terraform/              # All Terraform code
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        ├── user_data.tpl       # EC2 startup script (install Docker + run Strapi)

What Is the Task Concept?

You are building a complete CI/CD automation system for deploying a Strapi application using:

GitHub Actions (Automation)

Docker (Build Strapi image)

Terraform (Create AWS EC2 infrastructure)


Default VPC (Networking)

### Whenever you push code to GitHub, a new Strapi Docker image will be built → uploaded → and deployed to an EC2 server using Terraform.

## Using .github/workflows create the resources by terraform --> do any changes on your repo  -->  When trigger the terraform.yml manually mentione the builded decker image tag then automatically pull that image from ECR then it will create a docker container.
    
