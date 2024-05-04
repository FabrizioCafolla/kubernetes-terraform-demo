# API microservice with K8S and Terraform

### Objectives

The goal of the project is to create a local k8s infrastructure and delpoy microservices using Terraform.

**Constraints**

1. Create a monorepo that include infrustructure and microservices
2. Manage localstack with one-click
3. Save terraform state locally

## Let's start

### Requirements

- Python    >= 3.8
- Minikube  >= v1.32.0
- Docker    >= 25.0.0
- kubectl   >= v1.29.0
- Terraform >= 1.7.0

### Run local infrastructure

1. The `run.sh` command make it easy to manage the local k8s infrastructure, run these commands in your terminal:

   ```echo "api=true" > localstack/localstack.txt```

   ```chmod +x localstack/run.sh```

   ```./localstack/run.sh -t plan --create-localstack```

   ```./localstack/run.sh -t apply``` (opt *--create-localstack* only first run)
2. Expose cluster

   ```minikube tunnel```

3. Test ([All endpoint](app/api/README.md))
   - MacOS
     - Open browser: [http://localhost/health](http://localhost/health)
   - Linux
     - Get IP_MINIKUBE: ```minikube ip```
     - Add to **/etc/hosts**: `IP_MINIKUBE demo.local`
     - Open browser: [http://demo.local/health](http://demo.local/health)

### Dev mode

Once the starting infrastructure run.sh has worked you can start developing your microservices.

**Project structure**

- *microservices*

   This is where the microservices of your infrastructure reside. Each folder corresponds to a microservice so you can use any language it is OBLIGATORY to create:
   1. `Dockerfile`
   2. `infrastructure` folder containing the terraform main.tf, the various modules needed, and the env folder with the tfvars. The main file should retrieve the state of the shared infrastructure so that the shared resources can be accessed.

- *infrastructure*

   The `infrastructure` folder is the basic structure of our cluster. Here you can add all the services and containers common to all microservices. By default, it creates a namespace used.

- *localstack*

   This folder contains files useful for running the entire infrastructure locally. The files contained are:
   1. `localstack.txt` key-value file that allows you to indicate which microservices to run locally, so you can run only the services you need locally. The `key` is the name of the microservice (and its folder within `microservices`) while `value` is a true or false, for example `api=true`
   2. `run.sh` This script is an entry point that facilitates the startup of the local infrastructure
   3. `setup.sh` installs all dependencies for local development

**Exec**

```bash
chmod +x localstack/setup.sh

./localstack/setup.sh

source .activate

pre-commit run --all
```

### Unset

1. `./localstack/run.sh -t destroy`
2. `minikube delete`

### Dashboard

1. `minikube addons enable dashboard`
2. `minikube dashboard`
