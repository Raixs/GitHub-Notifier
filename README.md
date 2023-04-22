# GitHub Notifier

Este repositorio contiene un script de shell que utiliza la API de GitHub para obtener las notificaciones no leídas de un usuario y las muestra en el escritorio del usuario. El script utiliza notify-send, una biblioteca de notificaciones, para mostrar las notificaciones en el escritorio.

Se guarda un registro de las notificaciones que se han mostrado en el archivo `~/.github-notifier/shown_notifications.log`. Si se ejecuta el script nuevamente, solo se mostrarán las notificaciones que no se hayan mostrado anteriormente.

## Uso

Para utilizar el script, necesitas proporcionar un token de acceso personal de GitHub. Puedes generar un token de acceso personal en la configuración de tu cuenta de GitHub.

El script se puede ejecutar utilizando el siguiente comando:

```bash
./github_notifier.sh GITHUB_TOKEN
```

Reemplaza `GITHUB_TOKEN` con tu token de acceso personal de GitHub.

Si no hay notificaciones sin leer, el script no hará nada.

### Limitar que proyectos seran notificados

Si proporcionas una lista de proyectos desde el segundo argumento, solo se recibiran no tificaciones de dichos proyectos.
```bash
./github_notifier.sh GITHUB_TOKEN proyecto1 proyecto2 proyectoN
```

### Configuración de Apprise


El script utiliza Apprise para enviar las notificaciones a los serviciones que se deseen. Para configurar Apprise, se debe editar el archivo `~/.github-notifier/apprise.yml` y agregar las configuraciones de los servicios que se deseen. Para más información sobre Apprise, visita [su página web](https://github.com/caronc/apprise)

Se incluyen ejemplos comentados en el archivo `apprise.yml` para los servicios más populares.

## Dependencias

El script utiliza las siguientes dependencias:

-   `curl`
-   `jq`
-   `notify-send`
-   `apprise`
-   `python3`

### Tareas pendientes:

- [x] Migrar notify-send a Apprise.
- [x] Migrar a Python para hacerlo compatible con Windows.
- [x] Formatear el texto de la notifcación con más información.
