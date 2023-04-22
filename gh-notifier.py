#!/usr/bin/env python3

import os
import sys
import json
import requests
from apprise import Apprise, AppriseConfig

# Obtener el token de GitHub y lista de proyectos
GITHUB_TOKEN = sys.argv[1]
urls = sys.argv[2:]

# Archivo para llevar registro de notificaciones mostradas
shown_notifications_file = "shown_notifications.log"

# Obtener las notificaciones
headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": f"token {GITHUB_TOKEN}"
}
notifications = requests.get("https://api.github.com/notifications", headers=headers).json()

# Filtrar notificaciones no leídas de los proyectos indicados
if urls:
    regex = "|".join(urls)
    notifications = [n for n in notifications if n['unread'] and regex in n['subject']['url']]
else:
    notifications = [n for n in notifications if n['unread']]

# Si no hay notificaciones, no hacemos nada
if not notifications:
    sys.exit()

# Configurar Apprise
apprise_config_path = "./apprise.yml"
config = AppriseConfig()
config.add(apprise_config_path)

ap = Apprise()
ap.add(config)

# Función que envía notificaciones en el escritorio
def send_notification(title, body):
    ap.notify(title=title, body=body)

# Recorrer las notificaciones y enviar notificaciones
for notification in notifications:
    id = notification['id']
    title = notification['subject']['title']
    url = notification['subject']['url']
    repository = notification['repository']['full_name']

    # Verificar si la notificación ya ha sido mostrada
    with open(shown_notifications_file, "r") as f:
        if id not in f.read():
            # Si no ha sido mostrada, mostrarla y agregarla al archivo de registro
            details = requests.get(url, headers=headers).json()
            html_url = details.get('html_url')
            author = details.get('user', {}).get('login') or details.get('sender', {}).get('login')
            pull_request = details.get('pull_request')

            if pull_request:
                pr_details = requests.get(pull_request['url'], headers=headers).json()
                changes = f"{pr_details['commits']} commits, {pr_details['additions']} additions, {pr_details['deletions']} deletions"
            else:
                changes = ""

            message = f"Author: {author}\nRepository: {repository}\n{changes}\n\n{html_url}"
            send_notification(title, message)

            # Agregar la ID al archivo de registro de notificaciones mostradas
            with open(shown_notifications_file, "a") as f:
                f.write(f"{id}\n")
