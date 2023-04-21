# GitHub Notifier

Este repositorio contiene un script de shell que utiliza la API de GitHub para obtener las notificaciones no leídas de un usuario y las muestra en el escritorio del usuario. El script utiliza notify-send, una biblioteca de notificaciones, para mostrar las notificaciones en el escritorio.

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

## Dependencias

El script utiliza las siguientes dependencias:

-   `curl`
-   `jq`
-   `notify-send`

### Tareas pendientes:

- [ ] Migrar notify-send a Apprise.
- [ ] Formatear el texto de la notifcación con más información

