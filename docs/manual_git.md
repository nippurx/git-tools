# 📘 Manual de Git – Proyecto

## 🤔 ¿Por qué usamos estos alias?

Git es una herramienta **minimalista**: solo trae comandos básicos (`commit`, `push`, `tag`, `reset`…), y deja que cada equipo construya su propio flujo de trabajo.  
No existen comandos nativos como `git backup`, `git release` o `git rollback` porque Git considera que:

- El **backup** ya está en el historial de commits.  
- El **release** se hace simplemente con un `tag`.  
- El **rollback** se logra con `reset` o `revert`.  

👉 El problema es que estos comandos son largos, fáciles de olvidar y cada equipo los usa de forma distinta.  

Por eso definimos **3 alias personalizados** que resumen el flujo que necesitamos en este proyecto:

- **`git backup`** → crea un snapshot con la fecha, para poder volver en caso de error.  
- **`git release`** → libera una nueva versión estable, con commit + push + tag automático (y auto-incremento si hacés varias en el mismo día).  
- **`git rollback`** → vuelve rápidamente a un backup anterior; si no especificás cuál, vuelve al último disponible.  

Con estos atajos, todos los devs del proyecto trabajan con la misma lógica y evitan errores comunes.

---

## ⚙️ Configuración inicial (solo una vez por PC)

Copiá y pegá en **Git Bash**:

### Alias `git backup`
```bash
git config --global alias.backup '!sh -c "git tag backup-$(date +%Y-%m-%d) && git push origin backup-$(date +%Y-%m-%d)"'
```

👉 Uso:
```bash
git backup
```
Crea y sube `backup-YYYY-MM-DD` (ej: `backup-2025-09-17`).

---

### Alias `git release`
```bash
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
```

👉 Uso:
```bash
git release "Versión estable con subtítulos configurables"
git release    # sin mensaje → usa "Versión estable"
```

- Primer release del día: `v2025.09.17`  
- Segundo release: `v2025.09.17.1`  
- Tercero: `v2025.09.17.2`  

---

### Alias `git rollback`
```bash
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

👉 Uso:
```bash
git rollback backup-2025-09-17   # vuelve a un backup específico
git rollback                     # vuelve al último backup disponible
```

---

## 🚀 Flujo de trabajo recomendado

1. **Antes de empezar cambios**  
   ```bash
   git backup
   ```
   Guarda un snapshot seguro.  

2. **Trabajar en el código**  
   Editar, probar, testear.  

3. **Liberar versión estable**  
   ```bash
   git release "Versión estable con mejoras"
   ```
   Subirá cambios + tag estable.  

4. **Si algo falla**  
   ```bash
   git rollback
   ```
   Vuelve al último backup disponible.
