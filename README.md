# Git Tools

Alias simples para guardar avances, marcar versiones y restaurar proyectos:

```sh
git backup
git release "Versión lista"
git rollback
```

## Instalación

Requiere **Git 2.28 o posterior**. En Windows, instalá Git for Windows con Git disponible en PATH; su shell viene incluida y no necesitás abrir Git Bash. Configurá tu identidad una vez:

```sh
git config --global user.name "Tu nombre"
git config --global user.email "tu@email.com"
```

Cloná este repositorio o descargá y descomprimí el ZIP completo. Conservá la carpeta `lib` junto a los instaladores durante la instalación.

**Windows:** doble clic en `install.bat`, o desde PowerShell:

```powershell
.\install.bat
# Opcional: guardar tu cuenta/organización para git start
.\install.bat TU_USUARIO_GITHUB
# Sin preguntas ni pausa
.\install.bat --no-pause
```

**Git Bash / Linux / macOS:**

```sh
sh install.sh
# Opcional
sh install.sh TU_USUARIO_GITHUB
```

También podés ejecutar `powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1`.
No requiere administrador. Instala cinco alias en tu configuración global de Git; quedan disponibles en todos tus proyectos. Podés mover o borrar esta carpeta después: los alias son autónomos. Reinstalar actualiza esos cinco alias, conservando las demás opciones y alias de Git. Si ya tenías alias con estos nombres, se reemplazan.

## Comandos

| Comando | Resultado |
| --- | --- |
| `git start [mensaje] [URL]` | Inicializa en `main`, guarda y publica si hay remoto. Conserva la rama en repositorios existentes. |
| `git backup [mensaje]` | Guarda todos los cambios y crea `backup-YYYY-MM-DD-HHMMSS[.N]`. |
| `git release [mensaje]` | Guarda y etiqueta `vYYYY.MM.DD[.N]`. |
| `git rollback [tag]` | Restaura el último backup o release, o el tag indicado, mediante un nuevo commit. |
| `git rollback-release [tag]` | Igual, pero selecciona solamente releases. |

Todos operan sobre **la rama actual y el repositorio completo**, incluso al ejecutarlos desde una subcarpeta. Sin `origin`, trabajan localmente. Con `origin`, sincronizan tags y publican automáticamente; un fallo de conexión detiene el comando con error. Backup/release incluyen archivos nuevos, cambios y eliminaciones, respetando `.gitignore`.

**Rollback conserva el historial.** Requiere un árbol de trabajo limpio: si tenés cambios pendientes, guardalos con `git backup` y luego indicá el tag al que querés volver. No utiliza `reset --hard` ni `push --force`. Los archivos ignorados no forman parte de los backups; no uses estos comandos como respaldo de bases de datos, secretos o archivos externos.

```sh
git start "Inicio del proyecto"
git backup "Antes del cambio"
git release "Versión estable"
# Después de trabajar, guardar antes de volver a una versión anterior:
git backup
git rollback-release
# O elegir un punto concreto:
git tag --list
git rollback v2026.09.16
```

Un release crea un **tag de Git**, no una publicación en la sección Releases de GitHub.

## Usar con GitHub

Creá primero un repositorio vacío en tu cuenta (sin README ni commit inicial) y autenticá Git por HTTPS o SSH. Estos scripts no crean el repositorio en GitHub ni configuran credenciales.

Desde tu proyecto:

```sh
git start "Primer commit" https://github.com/TU_USUARIO/MI_PROYECTO.git
```

Si configuraste tu usuario al instalar y omitís la URL, `git start` usa `https://github.com/USUARIO/NOMBRE_CARPETA.git`. Un `origin` existente tiene prioridad; nunca se reemplaza silenciosamente.

Para compartir **Git Tools**, subí el proyecto completo a tu repositorio, incluidos `lib/`, los instaladores y la documentación. El remoto de este checkout puede inspeccionarse con `git remote -v`; para publicar en otra cuenta, ajustalo explícitamente con `git remote set-url origin URL` antes del push.

## Actualizar y desinstalar

Después de descargar una nueva versión, volvé a ejecutar el instalador.

Para desinstalar, ejecutá una vez cada línea:

```sh
git config --global --unset-all alias.start
git config --global --unset-all alias.backup
git config --global --unset-all alias.release
git config --global --unset-all alias.rollback
git config --global --unset-all alias.rollback-release
git config --global --unset-all git-tools.github-owner
```

## Pruebas y guía móvil

`python tests/integration.py` ejecuta pruebas con configuraciones aisladas y remotos locales; Python solo es necesario para desarrollar, no para usar los alias. GitHub Actions ejecuta las pruebas en Windows, Linux y macOS.

La carpeta [app](app/index.html) contiene una guía/generador PWA; no ejecuta Git. Publicala con GitHub Pages para abrirla como sitio HTTPS en `https://USUARIO.github.io/REPOSITORIO/app/`. Abrir el HTML directamente desde GitHub no instala la PWA. El generador produce comandos para **Git Bash / sh**. La guía funciona offline después de la primera carga.

Más detalles en el [manual](docs/manual_git.md).

## Licencia

[MIT](LICENSE).