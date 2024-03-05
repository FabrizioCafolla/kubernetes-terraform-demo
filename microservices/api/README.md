# Api

Exposes following  RESTFUL endpoints (no database required) with all **CRUD** operations

|**Rest API** call          | **CRUD** operation | REST endpoints|
|:----:                 |:----:           |:----:|
|**GET**                | **R**ead        | `http://localhost/` <br /> `http://localhost/health`  <br /> `http://localhost/api/todos`  <br /> `http://localhost/api/todos/{id}`|
|**PATCH/PUT**          | **U**pdate     | `http://localhost/api/todos/{id}`|
|**POST** {with body}   | **C**reate      | `http://localhost/api/todos`|
|**DELETE**             | **D**elete      | `http://localhost/api/todos/{id}` |
|**GET**             | **H**ealthceck     | `http://localhost/api/health` |


You may get 3 types of **response**

  |Response `Code`  | Response `Status` |
  |:---------------:|:-----------------:|
  |     **200**     |       `OK`        |
  |     **201**     |     `Created`     |
  |     **404**     |    `Not Found`    |


## Project setup

### Localstack

Exec **run.sh** from `localstack/run.sh` (create localstack.txt and paste: `api=true`)

If you want you can run commands manualy

    cd infrastructure

    terraform init
    terraform workspace select --or-create WORKSPACE_NAME

    terraform plan -var-file env/WORKSPACE_NAME.tfvars
    terraform apply -var-file env/WORKSPACE_NAME.tfvars

## Microservice code

Author : https://github.com/eaccmk
