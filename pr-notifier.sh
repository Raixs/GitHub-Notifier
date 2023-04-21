#!/bin/bash

GITHUB_TOKEN="${1}"

urls=("${@:2}") # Lista de argumentos desde el segundo argumento

# Obtener las notificaciones
notifications=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/notifications)

# Recorremos la lista de valores concatenandoles con "|"
for url_search in "${urls[@]}"; do
    regex+="|${url_search}" # Concatenar el valor del elemento del array en la variable urls_string, separado por |
done
regex="${regex:1}" # Eliminar el primer caracter, que es un pipe generado en el bucle anterior

# Mostrar solo las notificaciones que no se han leído de los proyectos indicados.
notifications=$(echo "${notifications}" | jq -r --arg regex "${regex}" '.[] | select(.unread == true and (.subject.url | test($regex))) | {title: .subject.title, url: .subject.url}')

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
    # Send ourselves a DBus related desktop notification
    #apprise -vv -t "$1" -b "$2" dbus://
    notify-send -a "Github Notifier" "$1" "$2" #-i "$3"
}

# Recorrer el .json de las notificaciones y sacar notificaciones
echo "${notifications}" | jq -r '.title, .url' | while read -r title; read -r url; do
    #usando la URL de la notificación, obtener el html_url de la página usando la API de github
    url=$(curl -L -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" ${url} | jq -r '.html_url')
    url="<a href=\"$url\">$url</a>"
    notify "$title" "$url" #"$icon"
done