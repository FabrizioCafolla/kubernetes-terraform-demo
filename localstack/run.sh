#!/bin/bash
# Description:  Semplicemente è un wrapper di terraform che runna i microservizi a seconda della propria necessità, questo script consente di gestire l'intera infrastruttura locale in quanto si occupa di
#               1. Startare minikube e le dipendenze
#               2. Inizializzare l'infrastruttura base
#               3. Runnare tutti i microservizi (o solo quello desiderato) attraverso il file localstack.txt

set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

set -o pipefail

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

start_minikube(){
    echo "Starting minikube"

    minikube status || minikube start --driver=docker

    minikube addons enable ingress

    eval $(minikube -p minikube docker-env)
}

tf_run(){
    local _infrastructure_dir=${1:-""}
    local _arg_tf_cmd=${2:-""}
    local _arg_tf_opts=${3:-""}
    local _arg_env=${4:-"dev"}

    cd ${_infrastructure_dir}

    terraform init
    terraform workspace select --or-create ${_arg_env}

    if [ "$_arg_tf_cmd" == "plan" ]; then
        terraform plan ${_arg_tf_opts}
        return
    fi

    terraform ${_arg_tf_cmd} ${_arg_tf_opts}

    cd -
}

usage(){
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help          Show this help message and exit"
    echo "  -i, --init          Initialize the infrastructure"
    echo "  -e, --env           Environment to deploy (default: dev)"
    echo "  -t, --tf-cmd        Terraform command to run"
    echo "  -o, --tf-opts       Terraform options"
    echo "  --only-ms           Only run the specified microservice"
}

main(){
    cd ${WORKDIR}

    local _arg_create_localstack=false
    local _arg_destroy_localstack=false
    local _arg_only_microservice=""
    local _arg_tf_cmd=""
    local _arg_tf_opts=""
    local _arg_env="dev"

    while [ "$1" != "" ]; do
        case $1 in
            -h | --help ) usage
                exit
                ;;
            -c | --create-localstack ) _arg_create_localstack=true
                ;;
            -d | --destroy-localstack ) _arg_destroy_localstack=true
                ;;
            --only-ms ) shift
                _arg_only_microservice=$1
                ;;
            -e | --env ) shift
                _arg_env=$1
                ;;
            -o | --tf-opts ) shift
                _arg_tf_opts=$1
                ;;
            --tf-opts=* ) shift
                _arg_tf_opts="${1#*=}"
                ;;
            -t | --tf-cmd ) shift
                _arg_tf_cmd=$1
                ;;
            --tf-cmd=* ) shift
                _arg_tf_cmd="${1#*=}"
                ;;
            * ) echo "Unknown option $1"
                exit 1
        esac
        shift
    done

    if [ -z $_arg_tf_cmd ]; then
        echo "Terraform command is required"
        exit 1
    fi

    start_minikube

    if [ "$_arg_create_localstack" == "true" ]; then
        tf_run "infrastructure" "init" "" $_arg_env
        TF_VAR_namespace_name="$_arg_env" tf_run "infrastructure" "apply" "" $_arg_env
    fi

    local _localstack_enabled_microservices=($(cat localstack/localstack.txt | awk -F'\n' '{print $1}'))

    if [[ "${_localstack_enabled_microservices}" == "" ]]; then
        echo -e "\nNo microservice enabled. \nSee README.md and create localstack.txt file"
        exit 0
    fi

    for ms in $_localstack_enabled_microservices ; do
        local _microservice_name=${ms%%=*}
        local _is_enabled=${ms##*=}
        local _varfile="microservices/${_microservice_name}/infrastructure/env/${_arg_env}.tfvars"

        if [ "$_arg_only_microservice" != "" ] && [ "$_arg_only_microservice" != "$_microservice_name" ]; then
            continue
        fi

        if [ "$_is_enabled" == "true" ]; then
            echo "Create: ${_microservice_name}"

            if [ -f $_varfile ]; then
                _arg_tf_opts="${_arg_tf_opts} -var-file env/${_arg_env}.tfvars"
            else
                echo "Terraform varfile does not exist: ${_varfile}"
            fi


            tf_run "microservices/${_microservice_name}/infrastructure" "$_arg_tf_cmd" "$_arg_tf_opts" "$_arg_env"
        else
            echo "Skip: ${_microservice_name}"
        fi
    done

    if [ "$_arg_destroy_localstack" == "true" ]; then
        TF_VAR_namespace_name="$_arg_env" tf_run "infrastructure" "destroy" "" $_arg_env
    fi
}

main $@
