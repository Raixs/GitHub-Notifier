#!/bin/bash

GITHUB_TOKEN="${1}"

urls=("${@:2}") # Lista de argumentos desde el segundo argumento

# Archivo para llevar registro de notificaciones mostradas
shown_notifications_file="shown_notifications.log"

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

# Recorrer el .json de las notificaciones y sacar notificaciones
echo "${notifications}" | jq -r '.id, .title, .url, .repository' | while read -r id; read -r title; read -r url; read -r repository; do
    # Verificar si la notificación ya ha sido mostrada
    if ! grep -q "${id}" "${shown_notifications_file}"; then
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