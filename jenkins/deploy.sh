#!/bin/bash

function detect_language() {
    local file_patterns=(
        ["Makefile"]="c"
        ["app/pom.xml"]="java"
        ["package.json"]="javascript"
        ["requirements.txt"]="python"
        ["app/main.bf"]="befunge"
        ["CMakelists.txt"]="cpp"
    )
    local language_detected=()
    for file in "${!file_patterns[@]}"; do
        if [[ -f $file || ($(find . -type f -name "$file") != "") ]]; then
            language_detected+=("${file_patterns[$file]}")
        fi
    done
    if [[ -f Makefile && $(find . -type f -name "*.bf") ]]; then
        language_detected+=("brainfuck")
    fi
    echo "${language_detected[@]}"
}

function build_and_push_image() {
    local image_name=$DOCKER_REGISTRY/whanos/whanos-$1-$2
    local dockerfile_arg=""
    if [[ ! -f Dockerfile ]]; then
        dockerfile_arg="-f /images/$2/Dockerfile.standalone"
    fi
    docker build . "$dockerfile_arg" -t "$image_name" || exit 1
    docker push "$image_name" || exit 1
}

function deploy_or_clean() {
    if [[ -f whanos.yml ]]; then
        helm upgrade -if whanos.yml "$1" /helm/AutoDeploy --set image.image="$image_name" --set image.name="$1-name"
        get_external_ip "$1"
    else
        if helm status "$1" &> /dev/null; then
            helm uninstall "$1"
        fi
    fi
}

function get_external_ip() {
    local external_ip=""
    local ip_timeout=20
    echo "Trying to get the external IP:"
    while [ -z "$external_ip" ]; do
        if [[ "$ip_timeout" -eq 0 ]]; then
            echo "Couldn't get the IP: Timeout"
            return
        fi
        sleep 5
        echo -n "."
        external_ip=$(kubectl get svc "$1-lb" --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
        ip_timeout=$((ip_timeout - 1))
    done
    # shellcheck disable=SC2028
    echo "\n$external_ip"
}

LANGUAGES=$(detect_language)
if [[ -z $LANGUAGES ]]; then
    echo "Invalid project: no language matched."
    exit 1
fi
if (( ${#LANGUAGES[@]} != 1 )); then
    echo "Invalid project: multiple language matched (${LANGUAGES[*]})."
    exit 1
fi
echo "${LANGUAGES[0]} matched"

build_and_push_image "$1" "${LANGUAGES[0]}"
deploy_or_clean "$1"
