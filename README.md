# 🚀 Git Aliases – Backup, Release & Rollback

[![Git](https://img.shields.io/badge/Git-%23F05032.svg?style=for-the-badge&logo=git&logoColor=white)](https://git-scm.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=for-the-badge)](LICENSE)
[![Made with ♥](https://img.shields.io/badge/Made%20with-♥-red.svg?style=for-the-badge)](#)

Un conjunto de **alias personalizados para Git** que simplifican el flujo de trabajo en proyectos pequeños y medianos.  
Incluye comandos para **backup, release y rollback**.

---

## ✨ Características

- `git backup` → snapshot seguro del estado actual.  
- `git release` → crea y sube una versión estable (con auto-incremento si hacés varias en el día).  
- `git rollback` → vuelve rápidamente a un backup anterior o al último disponible.  

---

## ⚙️ Instalación

Ejecutá en **Git Bash**:

```bash
# Alias backup
git config --global alias.backup '!sh -c "git tag backup-$(date +%Y-%m-%d) && git push origin backup-$(date +%Y-%m-%d)"'

# Alias release
git config --global alias.release '!f(){
  msg=${1:-"Versión estable"};
  base=v$(date +%Y.%m.%d);
  tag=$base;
  n=1;
  git add .;
  git commit -m "$msg" || true;
  git push origin main;
  while git rev-parse -q --verify "refs/tags/$tag" >/dev/null || git ls-remote --tags origin | grep -q "$tag"; do
    tag="$base.$n"; n=$((n+1));
  done;
  git tag -a "$tag" -m "$msg";
  git push origin "$tag";
  echo "✅ Release creado: $tag";
}; f'

# Alias rollback
git config --global alias.rollback '!f(){
  tag=${1:-""};
  git fetch --tags;
  if [ -z "$tag" ]; then
    tag=$(git tag --list "backup-*" | sort | tail -n 1);
    if [ -z "$tag" ]; then
      echo "❌ No se encontraron backups para volver atrás.";
      exit 1;
    fi;
    echo "ℹ️ No se especificó tag, usando último backup: $tag";
  fi;
  git reset --hard "$tag";
  git push origin main --force;
  echo "⏪ Rollback completado a: $tag";
}; f'
```

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
   ```bash
   git rollback
   ```

---

## 📌 Ejemplos

```bash
git backup
# -> backup-2025-09-17

git release "Versión estable con subtítulos configurables"
# -> v2025.09.17 o v2025.09.17.1 si ya existía

git rollback
# -> vuelve al último backup disponible
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
