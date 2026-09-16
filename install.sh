#!/usr/bin/env sh
# Script de instalación automática de alias de git-tools

echo "⚙️ Instalando alias de git-tools..."

# Usa el usuario indicado, conserva el ya configurado o lo solicita en terminal.
github_owner=${1:-$(git config --global --get git-tools.github-owner 2>/dev/null || true)}
if [ -z "$github_owner" ] && [ -t 0 ]; then
  printf "Escribi tu usuario de GitHub (Enter para omitir): "
  read -r github_owner
fi
if [ -n "$github_owner" ]; then
  git config --global git-tools.github-owner "$github_owner" || exit 1
  echo "Usuario de GitHub configurado: $github_owner"
else
  echo "Usuario de GitHub omitido: git start requerira una URL remota."
fi

# Alias start (inicializar proyecto desde cero)
git config --global alias.start '!f(){
  msg="Initial commit";
  remote="";
  for arg in "$@"; do
    if echo "$arg" | grep -qE "^(http://|https://|git@)"; then
      remote="$arg";
    else
      msg="$arg";
    fi;
  done;
  git init || exit 1;
  git branch -M main || exit 1;
  if ! git config user.name >/dev/null 2>&1 || ! git config user.email >/dev/null 2>&1; then
    echo "⚠️ Advertencia: No se ha configurado la identidad de Git (user.name / user.email).";
  fi;
  git add . || exit 1;
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    if ! git diff --cached --quiet; then
      git commit -m "$msg" || exit 1;
    fi;
  else
    git commit -m "$msg" || git commit --allow-empty -m "$msg" || exit 1;
  fi;
  if [ -z "$remote" ]; then
    remote=$(git remote get-url origin 2>/dev/null || true);
  fi;
  if [ -z "$remote" ]; then
    owner=$(git config --global --get git-tools.github-owner 2>/dev/null || true);
    repo=${PWD##*/};
    if [ -n "$owner" ]; then
      remote="https://github.com/$owner/$repo.git";
      echo "Usando repositorio remoto detectado: $remote";
    fi;
  fi;
  if [ -z "$remote" ]; then
    echo "ERROR: no se encontro un repositorio remoto. Usa: git start \"$msg\" https://github.com/usuario/repositorio.git";
    exit 1;
  fi;
  current=$(git remote get-url origin 2>/dev/null || true);
  if [ "$current" != "$remote" ]; then
    git remote remove origin 2>/dev/null || true;
    git remote add origin "$remote" || exit 1;
  fi;
  git push -u origin main || exit 1;
  echo "Proyecto inicializado y publicado en: $remote";
}; f'

# Alias backup
git config --global alias.backup '!sh -c "d=$(date +%Y-%m-%d-%H%M%S); git add .; git diff --cached --quiet || git commit -m \"Backup $d\"; git tag backup-$d; git push origin HEAD; git push origin backup-$d"'

# Alias release
git config --global alias.release '!f(){
  msg=${1:-"Versión estable"};
  base=v$(date +%Y.%m.%d);
  tag=$base;
  n=1;
  git remote get-url origin >/dev/null 2>&1 || { echo "ERROR: no existe el remoto origin."; exit 1; };
  git add . || exit 1;
  git commit -m "$msg" || true;
  git push origin main || exit 1;
  while git rev-parse -q --verify "refs/tags/$tag" >/dev/null || git ls-remote --tags origin | grep -q "$tag"; do
    tag="$base.$n"; n=$((n+1));
  done;
  git tag -a "$tag" -m "$msg" || exit 1;
  git push origin "$tag" || exit 1;
  echo "✅ Release creado: $tag";
}; f'

# Alias rollback
git config --global alias.rollback '!f(){
  tag=${1:-""};
  git fetch --tags;
  if [ -z "$tag" ]; then
    tag=$(git for-each-ref --sort=-creatordate --format "%(refname:short)" refs/tags | grep -E "^(backup-|release-|v)" | head -n 1);
    if [ -z "$tag" ]; then
      echo "❌ No se encontraron ni backups ni releases.";
      exit 1;
    fi;
    echo "ℹ️ No se especificó tag, usando último encontrado: $tag";
  fi;
  git reset --hard "$tag";
  if git remote | grep -q origin; then
    git push origin main --force;
  fi;
  echo "⏪ Rollback completado a: $tag";
}; f'

# Alias rollback-release
git config --global alias.rollback-release '!f(){
  tag=${1:-""};
  git fetch --tags;
  if [ -z "$tag" ]; then
    tag=$(git for-each-ref --sort=-creatordate --format "%(refname:short)" refs/tags | grep -E "^(release-|v)" | head -n 1);
    if [ -z "$tag" ]; then
      echo "❌ No se encontraron releases para volver atrás.";
      exit 1;
    fi;
    echo "ℹ️ No se especificó tag, usando último release: $tag";
  fi;
  git reset --hard "$tag";
  if git remote | grep -q origin; then
    git push origin main --force;
  fi;
  echo "⏪ Rollback a release completado: $tag";
}; f'

echo "✅ ¡Todos los alias de git-tools han sido instalados con éxito!"
