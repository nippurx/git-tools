# 🚀 Git Aliases – Backup, Release & Rollback

[![Git](https://img.shields.io/badge/Git-%23F05032.svg?style=for-the-badge\&logo=git\&logoColor=white)](https://git-scm.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=for-the-badge)](LICENSE)
[![Made with ♥](https://img.shields.io/badge/Made%20with-♥-red.svg?style=for-the-badge)](#)

Un conjunto de **alias personalizados para Git** que simplifican el flujo de trabajo en proyectos pequeños y medianos.
Incluye comandos para **backup, release y rollback**.

---

## ✨ Características

* `git backup` → snapshot seguro del estado actual (siempre crea tag, aunque no haya cambios).
* `git release` → crea y sube una versión estable (con auto-incremento si hacés varias en el día).
* `git rollback` → vuelve rápidamente al último **backup o release** disponible.
* `git rollback-release` → vuelve siempre al último **release estable**, ignorando los backups.

---

## ⚙️ Instalación

Ejecutá en **Git Bash** los comandos de configuración que están en este README.
(Ver sección de alias más arriba).

---

## 🚀 Flujo de trabajo

1. **Antes de tocar nada**

   ```bash
   git backup
   ```

2. **Trabajar en el código** ✍️

3. **Liberar versión estable**

   ```bash
   git release "Versión estable con mejoras"
   ```

4. **Si algo falla**

   * Volver al último tag creado (backup o release):

     ```bash
     git rollback
     ```
   * Volver explícitamente al último release estable:

     ```bash
     git rollback-release
     ```

---

## 📌 Ejemplos

```bash
git backup
# -> backup-2025-09-18-120530

git release "Versión estable con subtítulos configurables"
# -> v2025.09.18 o v2025.09.18.1 si ya existía

git rollback
# -> vuelve al último tag disponible (backup o release)

git rollback-release
# -> vuelve al último release estable, ignorando backups
```

---

## 📖 Documentación extendida

Para más detalles sobre el uso de los alias:

👉 [Manual completo de uso](docs/manual_git.md)

---

## 📄 Licencia

Este proyecto se publica bajo la licencia [MIT](LICENSE).
Podés usarlo, modificarlo y compartirlo libremente.

---
