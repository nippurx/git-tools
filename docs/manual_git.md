# 📘 Manual de Git – Proyecto

## 🤔 ¿Por qué usamos estos alias?

Git es una herramienta **minimalista**: solo trae comandos básicos (`commit`, `push`, `tag`, `reset`…), y deja que cada equipo construya su propio flujo de trabajo.
No existen comandos nativos como `git backup`, `git release` o `git rollback` porque Git considera que:

* El **backup** ya está en el historial de commits.
* El **release** se hace simplemente con un `tag`.
* El **rollback** se logra con `reset` o `revert`.

👉 El problema es que estos comandos son largos, fáciles de olvidar y cada equipo los usa de forma distinta.

Por eso definimos **4 alias personalizados** que resumen el flujo que necesitamos en este proyecto:

* **`git backup`** → crea un snapshot con fecha y hora, incluso si no hay cambios, para poder volver en caso de error.
* **`git release`** → libera una nueva versión estable, con commit + push + tag automático (y auto-incremento si haces varias en el mismo día).
* **`git rollback`** → vuelve rápidamente al último tag disponible (sea backup o release); también acepta un tag específico.
* **`git rollback-release`** → vuelve siempre al último **release estable**, ignorando los backups.

Con estos atajos, todos los devs del proyecto trabajan con la misma lógica y evitan errores comunes.

---

## ⚙️ Configuración inicial (solo una vez por PC)

Copiá y pegá en **Git Bash** los alias (ya están en el README).

---

## 🚀 Uso de los alias

### `git backup`

👉 Uso:

```bash
git backup
```

* Crea un commit (si hay cambios).
* Genera un tag con el formato `backup-YYYY-MM-DD-HHMMSS`.
* Si hay remoto → lo sube.
* Si no hay remoto → queda local.
* Siempre muestra en pantalla el nombre del tag creado.

---

### `git release`

👉 Uso:

```bash
git release "Versión estable con subtítulos configurables"
git release    # sin mensaje → usa "Versión estable"
```

* Primer release del día: `v2025.09.18`
* Segundo release: `v2025.09.18.1`
* Tercero: `v2025.09.18.2`
* Hace commit si hay cambios, crea el tag y lo sube si hay remoto.

---

### `git rollback`

👉 Uso:

```bash
git rollback backup-2025-09-18-120500   # vuelve a un backup específico
git rollback v2025.09.18                # vuelve a un release específico
git rollback                            # sin tag → vuelve al último backup o release disponible
```

* Detecta automáticamente el último tag válido (`backup-*`, `release-*` o `v*`).
* Hace un `reset --hard` a ese punto.
* Si hay remoto, fuerza la sincronización (`push --force`).

---

### `git rollback-release`

👉 Uso:

```bash
git rollback-release v2025.09.18   # vuelve a un release específico
git rollback-release               # sin tag → vuelve al último release estable
```

* Ignora backups.
* Siempre toma la última versión marcada como release.
* Ideal para restaurar el último estado “estable” en producción.

---

## 🚀 Flujo de trabajo recomendado

1. **Antes de empezar cambios**

   ```bash
   git backup
   ```

   Guarda un snapshot seguro (aunque no hayas modificado nada).

2. **Trabajar en el código**
   Editar, probar, testear.

3. **Liberar versión estable**

   ```bash
   git release "Versión estable con mejoras"
   ```

   Subirá cambios + tag estable (único por día con auto-incremento).

4. **Si algo falla en el desarrollo**

   ```bash
   git rollback
   ```

   Vuelve al último snapshot disponible (sea backup o release).

5. **Si todo falla y necesitas volver a lo último realmente estable**

   ```bash
   git rollback-release
   ```

   Vuelve al último release, ignorando los backups.

---
