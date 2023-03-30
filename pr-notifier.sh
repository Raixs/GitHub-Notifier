#!/bin/bash

GITHUB_TOKEN="$1"

# Obtener las notificaciones
notifications=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/notifications)

# Mostrar solo las notificaciones que no se han leído
notifications=$(echo "$notifications" | jq -r '.[] | select(.unread == true) | {title: .subject.title, url: .subject.url}')

# Si no hay notificaciones, no hacemos nada
if [ -z "$notifications" ]
then
    exit
fi

# Configurar Apprise
apprise_config_path="./apprise.yml"
export APPRISE_CONFIG="$apprise_config_path"

# Función que saca notificaciones en el escritorio con el titulo y descripción como parámetros
function notify {
    # Send ourselves a DBus related desktop notification
    #apprise -vv -t "$1" -b "$2" dbus://
    notify-send -a "Github Notifier" "$1" "$2" #-i "$3"
}

# Recorrer el .json de las notificaciones y sacar notificaciones
echo "$notifications" | jq -r '.title, .url' | while read -r title; read -r url; do
    #usando la URL de la notificación, obtener el html_url de la página usando la API de github
    url=$(curl -L -H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" $url | jq -r '.html_url')
    url="<a href=\"$url\">$url</a>"
    notify "$title" "$url" #"$icon"
done