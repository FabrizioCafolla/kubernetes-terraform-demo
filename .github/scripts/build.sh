#!/bin/bash
# Description:  build.sh è lo script che consente di gestire il build delle immagini in modo univoco e standard per tutti i microservizi
#               cosentendo di gestire i vari ambienti locale, staging e production allo stesso modo.
#               Crea in output il file .dockerimage che può essere utilizzato dallo script terraform per recuperare l'immagine appena buildata

set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

set -o pipefail

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../../microservices"

main(){
    local _arg_microservice_name=${1}
    local _arg_microservice_version=${2}
    local _arg_load_minikube_docker_env=${3:-"false"}
    local _arg_docker_filedir=${4:-""}

    if [ "$_arg_microservice_name" == "" ]; then
        echo "microservice_name is not set"
        exit 1
    fi

    if [ "$_arg_microservice_version" == "" ]; then
        echo "microservice_version  is not set"
        exit 1
    fi

    if [ "$_arg_docker_filedir" == "" ]; then
        _arg_docker_filedir="${WORKDIR}/${_arg_microservice_name}"
    fi

    cd ${_arg_docker_filedir}

    if [[ "$_arg_load_minikube_docker_env" == "true" ]]; then
        eval $(minikube -p minikube docker-env) # Load minikube docker env in local infrastructure
    fi

    local _image_name="${_arg_microservice_name}:${_arg_microservice_version}"

    echo "Building the image ${_image_name}"

    docker build -t ${_image_name} .

    if [[ "$_arg_load_minikube_docker_env" == "true" ]]; then
        _image_sha="$(docker images --quiet ${_image_name})"
        docker tag ${_image_name} ${_arg_microservice_name}:${_image_sha} # TODO: create tag with sha256 because  minikube cannot retrieve the image via sha256.
        printf "${_image_sha}" > .dockerimage
        exit 0
    fi

    printf "${_arg_microservice_version}" > .dockerimage
}

main $@
