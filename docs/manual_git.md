# Manual de Git Tools

## Instaladores

`install.bat` invoca Windows PowerShell y conserva el código de salida. Acepta `--no-pause [usuario]` para automatización. `install.ps1` acepta `-GitHubOwner` y `-NonInteractive`. `install.sh` solicita el usuario solamente en una terminal interactiva.

Ambos instaladores leen `lib/commands.sh` e insertan exactamente la misma implementación en cinco alias globales. No agregan ejecutables al PATH ni requieren esta carpeta para funcionar después de instalar. Las opciones locales del repositorio pueden sobreescribir los alias globales.

## Guardar y publicar

`start`, `backup` y `release` incluyen todos los archivos no ignorados del repositorio. Revisá tu `.gitignore` antes de usarlos. Crean un commit solo si hay cambios, salvo el primer commit, que puede estar vacío. Los errores de identidad, hooks o firma detienen el comando; no se crea una etiqueta si el commit falla.

Backup y release usan etiquetas anotadas. Si el nombre existe, agregan `.1`, `.2`, etc. Antes consultan los tags de `origin`, cuando existe. Una carrera entre dos equipos puede rechazar la publicación, pero nunca sobreescribe tags.

Con remoto, la rama actual y la etiqueta se publican con `git push --atomic`. Si el servidor rechaza la operación, ambos permanecen locales y se muestra un comando de reintento. No se informa éxito remoto cuando falla. El servidor debe soportar push atómico. Los cambios locales no se deshacen automáticamente.

No se hace pull ni merge automático: si otro equipo avanzó la rama, integrá sus cambios antes de reintentar el push. Se respetan los hooks, firmas y reglas de protección del servidor.

## Inicializar

`git start [mensaje] [URL]` reconoce URLs HTTPS, HTTP, SSH, `git@...` y `file://...`. Crea una rama `main` solamente al inicializar un repositorio nuevo. En uno existente conserva la rama actual, incluso desde subdirectorios.

El remoto se resuelve por URL explícita, `origin` existente o usuario configurado más nombre de carpeta. Si no hay ninguno, funciona localmente. No reemplaza un `origin` distinto: exige cambiarlo explícitamente. El repositorio remoto debe existir; el instalador no autentica ni crea repositorios en GitHub.

## Restaurar

`git rollback [tag]` restaura el árbol del tag mediante `git restore` y crea un commit sobre la rama actual. Las eliminaciones y altas de archivos rastreados también se restauran. El historial previo se conserva y el push es normal.

Sin argumento selecciona tags `backup-YYYY-MM-DD-HHMMSS[.N]`, `vYYYY.MM.DD[.N]` y los antiguos `release-...`, ordenados por fecha de creación descendente. Empates en el mismo segundo se resuelven por nombre en orden de versión descendente. Para elegir sin ambigüedad usá un tag explícito. Los tags antiguos livianos usan la fecha del commit. La selección abarca todos los tags locales y descargados, incluso de otras ramas.

`rollback-release` excluye backups y exige un nombre de release cuando se indica uno explícitamente. `rollback` admite cualquier tag existente que apunte a un commit; no admite nombres de ramas ni revisiones arbitrarias.

Ambos requieren no tener cambios pendientes ni archivos sin seguimiento. Para conservarlos, ejecutá `git backup` antes y luego indicá el destino o usá `rollback-release`. Si el árbol ya coincide con el destino, no se crea un commit vacío. Si un hook rechaza el commit, la restauración queda en staging para revisión. Si falla el push, el commit local se conserva.

Los archivos ignorados no se respaldan ni se limpian; si su ruta coincide con un archivo del destino, la restauración puede reemplazarlos. Guardá fuera del repositorio los datos que no estén versionados antes de restaurar.

Los comandos rechazan HEAD separado, conflictos, merge/rebase/cherry-pick/revert pendientes y repositorios con submódulos. Administrá esas situaciones con Git antes de usar los alias.

## Desarrollo y comprobación

Ejecutá `python tests/integration.py`. Las pruebas crean repositorios temporales y remotos bare, aíslan la configuración global y verifican instalación repetida, equivalencia de instaladores Windows/sh, trabajo sin remoto, ramas alternativas, subdirectorios, rollback, hooks y rechazo de push atómico.

La PWA es una guía independiente. Para instalarla se necesita HTTPS o localhost y una primera carga online; Git se ejecuta en la terminal, no en el navegador.