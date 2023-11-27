#!/bin/bash

# ------------     Utils functions     ------------
### Get the external IP of the service
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

### Check if it is a brainfuck project
function is_brainfuck() {
    local is_brainfuck=false

    while IFS= read -r -d '' file; do
        read -n 1000 contenu < "$file"

        # Échapper correctement les caractères spéciaux dans l'expression régulière
        if echo "$contenu" | grep -qP '^[><+\-.,\[\]]+$'; then
            is_brainfuck=true
            break
        fi
    done < <(find . -name "*.bf" -type f -print0)

    echo "$is_brainfuck"
}
# ------------  End Utils functions   ------------


# ------------     Check language     ------------
function detect_language() {
    declare -A file_patterns
    file_patterns["CMakeLists.txt"]="cpp"
    file_patterns["Makefile"]="c"
    file_patterns["app/pom.xml"]="java"
    file_patterns["package.json"]="javascript"
    file_patterns["requirements.txt"]="python"
    file_patterns["app/main.bf"]="befunge"

    local language_detected=()
    for file in "${!file_patterns[@]}"; do
        if [[ -f "$file" ]]; then
            language_detected=("${file_patterns[$file]}")
            continue
        fi
    done
    if [[ -f "Makefile" && $(find . -type f -name "*.bf") != "" ]]; then
        language_detected=("brainfuck")
    fi
    echo "${language_detected[@]}"
}
# ------------   End Check language    ------------


# ------------     Build & Deploy      ------------
function build_and_push_image() {
    if [[ ! -f Dockerfile ]]; then
        docker build -f /images/$2/Dockerfile.standalone -t ${DOCKER_REGISTRY}/whanos/whanos-$1-$2 .
        docker push ${DOCKER_REGISTRY}/whanos/whanos-$1-$2 || exit 1
    else
      docker build -t ${DOCKER_REGISTRY}/whanos/whanos-$1-$2 .
    fi
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
# ------------  End Build & Deploy   ------------


# ------------     Main function     ------------
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
<<<<<<< Updated upstream
#deploy_or_clean "$1"
=======
deploy_or_clean "$1"
LANGUAGES=''
>>>>>>> Stashed changes
# ------------   End Main function   ------------
