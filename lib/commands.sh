# Shared implementation embedded in Git config by both installers.
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
repo() {
  [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || fail 'Ejecuta dentro de un repositorio.'
  branch=$(git symbolic-ref --quiet --short HEAD) || fail 'Cambia a una rama primero (HEAD separado).'
  for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
    [ ! -e "$(git rev-parse --git-path "$state")" ] || fail 'Termina o cancela la operacion Git en curso.'
  done
  [ -z "$(git ls-files -u)" ] || fail 'Resuelve los conflictos primero.'
  [ -z "$(git submodule status)" ] || fail 'Los submodulos requieren gestion manual.'
  has_origin=false
  if git remote get-url origin >/dev/null 2>&1; then has_origin=true; fi
}
fetch_tags() {
  if [ "$has_origin" = true ]; then git fetch --tags origin || fail 'No se pudo sincronizar origin.'; fi
}
save_commit() {
  git add --all || exit 1
  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    git commit --allow-empty -m "$msg" || exit 1
  else
    git diff --cached --quiet
    result=$?
    case "$result" in 0) ;; 1) git commit -m "$msg" || exit 1 ;; *) exit "$result" ;; esac
  fi
}
publish() {
  if [ "$has_origin" = true ]; then
    if [ -n "$tag" ]; then
      git push --atomic -u origin "HEAD:refs/heads/$branch" "refs/tags/$tag:refs/tags/$tag" || {
        printf 'Commit/tag conservados localmente. Reintenta: git push --atomic -u origin HEAD:refs/heads/%s refs/tags/%s:refs/tags/%s\n' "$branch" "$tag" "$tag" >&2
        exit 1
      }
    else
      git push -u origin "HEAD:refs/heads/$branch" || fail 'Commit conservado localmente. Reintenta: git push -u origin HEAD'
    fi
  fi
}
gt_main() {
  command=$1
  shift
  case "$command" in
    start)
      [ "$#" -le 2 ] || fail 'Uso: git start [mensaje] [URL]'
      msg='Initial commit'
      remote=''
      for arg in "$@"; do
        case "$arg" in https://*|http://*|ssh://*|git@*|file://*) remote=$arg ;; *) msg=$arg ;; esac
      done
      if ! git rev-parse --git-dir >/dev/null 2>&1; then git init -b main || exit 1; fi
      repo
      current=$(git remote get-url origin 2>/dev/null || :)
      if [ -n "$current" ] && [ -n "$remote" ] && [ "$current" != "$remote" ]; then
        fail 'origin apunta a otro repositorio. Usa git remote set-url origin URL para cambiarlo.'
      fi
      if [ -z "$remote" ]; then remote=$current; fi
      if [ -z "$remote" ]; then
        owner=$(git config --get git-tools.github-owner || :)
        root=$(git rev-parse --show-toplevel) || exit 1
        if [ -n "$owner" ]; then remote="https://github.com/$owner/${root##*/}.git"; fi
      fi
      if [ -n "$remote" ] && [ -z "$current" ]; then git remote add origin "$remote" || exit 1; fi
      repo
      fetch_tags
      save_commit
      tag=''
      publish
      printf 'Proyecto listo en la rama %s.\n' "$branch"
      ;;
    backup|release)
      [ "$#" -le 1 ] || fail "Uso: git $command [mensaje]"
      repo
      fetch_tags
      if [ "$command" = backup ]; then
        base=backup-$(date +%Y-%m-%d-%H%M%S)
        msg=${1:-"Backup $base"}
      else
        base=v$(date +%Y.%m.%d)
        msg=${1:-'Version estable'}
      fi
      tag=$base
      n=1
      while git show-ref --verify --quiet "refs/tags/$tag"; do tag="$base.$n"; n=$((n + 1)); done
      save_commit
      git tag -a "$tag" -m "$msg" || exit 1
      publish
      printf 'Guardado: %s\n' "$tag"
      ;;
    rollback|rollback-release)
      [ "$#" -le 1 ] || fail "Uso: git $command [tag]"
      repo
      [ -z "$(git status --porcelain --untracked-files=all)" ] || fail 'Hay cambios sin guardar. Ejecuta git backup antes del rollback.'
      fetch_tags
      pattern='^(backup-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}(\.[0-9]+)?|v[0-9]{4}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?|release-.+)$'
      if [ "$command" = rollback-release ]; then pattern='^(v[0-9]{4}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?|release-.+)$'; fi
      target=${1:-}
      if [ -z "$target" ]; then
        target=$(git for-each-ref --sort=-version:refname --sort=-creatordate --format='%(refname:short)' refs/tags | grep -E "$pattern" | head -n 1)
      fi
      [ -n "$target" ] || fail 'No hay tags compatibles para restaurar.'
      if [ "$command" = rollback-release ]; then
        printf '%s\n' "$target" | grep -Eq "$pattern" || fail 'Indica un tag de release.'
      fi
      git check-ref-format "refs/tags/$target" >/dev/null || fail 'Nombre de tag invalido.'
      commit=$(git rev-parse --verify "refs/tags/$target^{commit}") || fail 'El tag no existe o no apunta a un commit.'
      git rev-parse --verify HEAD >/dev/null 2>&1 || fail 'La rama no tiene commits.'
      git diff --quiet HEAD "$commit" --
      result=$?
      case "$result" in
        0) ;;
        1) git restore --source="$commit" --staged --worktree -- . || exit 1 ;;
        *) exit "$result" ;;
      esac
      git diff --cached --quiet
      result=$?
      case "$result" in
        0) ;;
        1) git commit -m "Rollback a $target" || fail 'El commit fallo. La restauracion queda en staging.' ;;
        *) exit "$result" ;;
      esac
      tag=''
      publish
      printf 'Restaurado: %s (historial conservado).\n' "$target"
      ;;
    *) fail 'Comando desconocido.' ;;
  esac
}
