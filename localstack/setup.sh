#!/bin/bash
# Description:  Esegue l'installazione di tutte le dipendeze necessarie per lo sviluppo locale.

set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

set -o pipefail

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.."

main(){
    cd ${WORKDIR}

    local _venv_path=".venv"
    local _os_name=$(uname -s)

    # Install requirements
    if [ ! -d "${_venv_path}" ]; then
        python3 -m venv ${_venv_path}
    fi
    source ${_venv_path}/bin/activate
    pip3 install --upgrade pip
    pip3 install -r requirements.txt

    # Install tflint
    if [ "${_os_name}" == "Linux" ]; then
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    elif [ "${_os_name}" == "Darwin" ]; then
        brew install tflint
    else
        echo "The operating system is not recognized as Linux or macOS."
    fi

    # Configure pre-commit
    pre-commit install
    pre-commit install --hook-type pre-push

    chmod +x localstack/run.sh
    chmod +x .github/scripts/build.sh
}

main "$@"
