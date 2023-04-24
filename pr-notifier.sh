#!/usr/bin/env bash

#set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on undeclared variable
set -o pipefail  # don't hide errors within pipes
# set -o xtrace  # track what is running - debugging

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # <-- get path of the script --> FULLPATH ./
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")" # <-- get full path name of the script --> FULLPATH/FULLNAME
__base="$(basename "${__file}" .sh)" # <-- get name of the script --> NAME (Whitout extension)
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- get root path of the script --> FULLPATH ../

#### BLOQUE DE CÓDIGO PARA EJECUTAR EL SCRIPT DESDE CRON ####

# Use the correct DISPLAY variable
# export DISPLAY=:0
# current_user=$(whoami)
# echo "Current user is: ${current_user}"
# export XAUTHORITY="/home/${current_user}/.Xauthority"
# echo "XAUTHORITY is set to: ${XAUTHORITY}"

# Obtener la dirección del bus de sesión D-Bus desde cron
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

function show_help {
    cat << EOF
Usage: ${0} GITHUB_TOKEN [project1 project2 ...]

This script fetches unread GitHub notifications and displays them as desktop notifications.

Arguments:
    GITHUB_TOKEN    Your personal GitHub access token.
    project1        (Optional) A list of projects to filter notifications for. Only notifications for the specified projects will be shown.

Options:
    -h, --help      Show this help message and exit.

EOF
}

# Check for help flag
if [[ "$#" -eq 1 ]] && { [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; }; then
    show_help
    exit 0
fi

GITHUB_TOKEN="${1}"

urls=("${@:2}") # Lista de argumentos desde el segundo argumento

# Archivo para llevar registro de notificaciones mostradas
shown_notifications_file="${__dir}/shown_notifications.log"

# Obtener las notificaciones
notifications=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/notifications)

# Recorremos la lista de valores concatenandoles con "|"
for url_search in "${urls[@]}"; do
    regex+="|${url_search}" # Concatenar el valor del elemento del array en la variable urls_string, separado por |
done
regex="${regex:1}" # Eliminar el primer caracter, que es un pipe generado en el bucle anterior

# Mostrar solo las notificaciones que no se han leído de los proyectos indicados.
notifications=$(echo "${notifications}" | jq -r --arg regex "${regex}" '.[] | select(.unread == true and (.subject.url | test($regex))) | {id: .id, title: .subject.title, url: .subject.url, repository: .repository.full_name}')

# Utilizar la variable 'notification' como sea necesario
# Si no hay notificaciones, no hacemos nada
if [ -z "${notifications}" ]
then
    exit
fi

# Configurar Apprise
apprise_config_path="./apprise.yml"
export APPRISE_CONFIG="${apprise_config_path}"

# Función que saca notificaciones en el escritorio con el titulo y descripción como parámetros
function notify {
    notify-send -a "Github Notifier" "$1" "$2" --urgency "critical" #-i "$3"
}

echo "notify function is defined"

# Recorrer el .json de las notificaciones y sacar notificaciones
echo "${notifications}" | jq -r '.id, .title, .url, .repository' | while read -r id; read -r title; read -r url; read -r repository; do
    # Verificar si la notificación ya ha sido mostrada
    if ! grep -q "${id}" "${shown_notifications_file}"; then
    echo "Sending notification for ID ${id}"
        # Si no ha sido mostrada, mostrarla y agregarla al archivo de registro
        # usando la URL de la notificación, obtener el html_url de la página y otros detalles usando la API de github
        details=$(curl -L -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "${url}" | jq -r '{html_url: .html_url, author: (.user.login // .sender.login), pull_request: .pull_request}')
        html_url=$(echo "${details}" | jq -r '.html_url')
        author=$(echo "${details}" | jq -r '.author')
        pull_request=$(echo "${details}" | jq -r '.pull_request')

        if [ "${pull_request}" != "null" ]; then
            pr_details=$(curl -L -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "${pull_request}" | jq -r '{changes: (.commits | tostring) + " commits, " + (.additions | tostring) + " additions, " + (.deletions | tostring) + " deletions"}')
            changes=$(echo "${pr_details}" | jq -r '.changes')
        else
            changes=""
        fi

        # Construir el mensaje de la notificación
        message="Author: ${author}\nRepository: ${repository}\n${changes}"
        html_url="<a href=\"$html_url\">$html_url</a>"
        notify "${title}" "${message}\n\n${html_url}"

        # Agregar la ID al archivo de registro de notificaciones mostradas
        echo "${id}" >> "${shown_notifications_file}"
    fi
done