# 📘 Manual de Referencia Técnica – Git Tools

Este manual proporciona una guía detallada sobre la filosofía, arquitectura y funcionamiento interno de cada uno de los alias incluidos en **Git Tools**.

---

## 💡 Filosofía y Motivación

Git nativo es una herramienta minimalista. Acciones habituales en el desarrollo de software (crear snapshots antes de refactorizar, etiquetar versiones estables por fecha con control de colisiones o revertir cambios en un repositorio remoto) requieren secuencias largas y complejas de comandos (`git reset --hard`, `git tag -a`, `git push --force`, `git ls-remote`).

**Git Tools** resuelve esto estandarizando el flujo de trabajo a través de 5 alias clave que garantizan:
* **Consistencia:** Todo el equipo sigue el mismo estándar de ramas (`main`) y formatos de etiquetas (`backup-YYYY-MM-DD-HHMMSS` y `vYYYY.MM.DD`).
* **Red de Seguridad:** Los snapshots (`git backup`) permiten experimentar sin temor a perder código funcional.
* **Automatización:** Los releases (`git release`) gestionan automáticamente el sufijo numérico en caso de múltiples despliegues en el mismo día.

---

## 🛠️ Especificación Detallada de Comandos

### 1. `git start` – Inicialización de Proyecto

Inicializa un repositorio Git asegurando las mejores prácticas desde el primer momento.

* **Sintaxis:**
  ```bash
  git start [mensaje_opcional] [url_remota_opcional]
  ```

* **Comportamiento Interno:**
  1. Ejecuta `git init` si el directorio actual no es un repositorio Git.
  2. Fuerza el nombre de la rama principal a `main` (`git branch -M main`).
  3. Verifica la presencia de la identidad de Git (`user.name` y `user.email`).
  4. Añade todos los archivos iniciales al staging (`git add .`) y crea el primer commit (admite `--allow-empty` si el directorio está vacío).
  5. Resuelve el remoto en este orden: URL proporcionada, `origin` existente o repositorio de GitHub con el mismo nombre de la carpeta bajo el usuario detectado durante la instalación.
  6. Registra el remoto como `origin` y ejecuta `git push -u origin main`. Si no puede determinar un remoto o el push falla, termina con error y no muestra un falso mensaje de éxito.

* **Ejemplos de Uso:**
  ```bash
  git start                                                      # commit y push al repo GitHub con el nombre de la carpeta
  git start "Inicializando estructura del proyecto"              # mensaje personalizado + push
  git start https://github.com/usuario/mi-repo.git             # commit inicial + vinculación y push a remoto
  git start "Mi primer commit" https://github.com/user/repo.git # mensaje + remoto
  ```

---

### 2. `git backup` – Snapshot Temporal

Crea un punto de restauración inmediato sin interrumpir el flujo de trabajo actual.

* **Sintaxis:**
  ```bash
  git backup
  ```

* **Comportamiento Interno:**
  1. Agrega todos los archivos modificados y no rastreados (`git add .`).
  2. Genera un commit automático solo si hay cambios pendientes (`Backup YYYY-MM-DD-HHMMSS`).
  3. Crea un tag liviano con formato `backup-YYYY-MM-DD-HHMMSS`.
  4. Si existe un servidor remoto `origin`, sube la rama y el tag automáticamente.

* **Caso de uso típico:** Ejecutar justo antes de un refactor importante o una prueba riesgosa en el código.

---

### 3. `git release` – Publicación de Versión Estable

Marca un hito de versión estable en el proyecto con auto-incremento inteligente.

* **Sintaxis:**
  ```bash
  git release [mensaje_opcional]
  ```

* **Lógica de Versionado:**
  * Primer release del día: `vYYYY.MM.DD` (ej. `v2026.07.24`).
  * Siguientes releases del mismo día: `vYYYY.MM.DD.1`, `vYYYY.MM.DD.2`, etc.

* **Comportamiento Interno:**
  1. Registra cualquier cambio pendiente en un commit con el mensaje indicado (o `"Versión estable"` por defecto).
  2. Consulta la lista de tags locales y remotos para determinar si la versión base del día ya existe.
  3. Incrementa la secuencia numérica hasta hallar un tag libre.
  4. Crea una etiqueta anotada (`git tag -a`) y realiza el push a `origin main` y al tag generado.

---

### 4. `git rollback` – Restauración al Último Snapshot

Devuelve el estado del repositorio al último punto de guardado (sea un `backup-` o un `release-`/`v`).

* **Sintaxis:**
  ```bash
  git rollback [tag_especifico_opcional]
  ```

* **Comportamiento Interno:**
  1. Sincroniza las etiquetas remotas (`git fetch --tags`).
  2. Si no se especifica un tag explícito, busca la última etiqueta creada según fecha.
  3. Ejecuta un reseteo forzado (`git reset --hard <tag>`).
  4. Si hay un remoto `origin`, fuerza la actualización en el servidor (`git push origin main --force`).

* **⚠️ Advertencia:** Este comando descarta de forma destructiva todos los cambios no guardados posteriores al tag seleccionado.

---

### 5. `git rollback-release` – Restauración Exclusiva a Release

Restaura el proyecto únicamente al último **release estable**, ignorando cualquier backup intermedio.

* **Sintaxis:**
  ```bash
  git rollback-release [tag_release_opcional]
  ```

* **Comportamiento Interno:**
  1. Filtra las etiquetas omitiendo las que inician con `backup-`.
  2. Selecciona la etiqueta de release más reciente (ej. `v2026.07.24.1`).
  3. Ejecuta `git reset --hard` y la sincronización forzada con `origin`.

---

## ⚙️ Instalación y Mantenimiento

Todos los alias se gestionan mediante los scripts de instalación ubicados en la raíz del proyecto:
- **Windows CMD / Explorador:** `install.bat TU_USUARIO_GITHUB` o [install.bat](../install.bat) mediante doble click.
- **PowerShell:** `.\install.ps1 -GitHubOwner TU_USUARIO_GITHUB`.
- **Git Bash / Linux / Mac:** `sh install.sh TU_USUARIO_GITHUB`.

El usuario configurado se guarda en `git-tools.github-owner` y permite que `git start` encuentre un repositorio con el mismo nombre que la carpeta local.

> [!TIP]
> **Idempotencia de la instalación:** Podés ejecutar el script de instalación tantas veces como desees. Si ya tenías alias instalados anteriormente y agregás una nueva versión de `git-tools`, Git añadirá los alias nuevos (como `git start`) y actualizará los existentes sin duplicar líneas en tu archivo `~/.gitconfig`.

Para consultar los alias registrados en tu sistema podés ejecutar:
```bash
git config --global --get-regexp "^alias\."
```
