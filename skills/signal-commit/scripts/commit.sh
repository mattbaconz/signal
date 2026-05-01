#!/usr/bin/env bash
set -euo pipefail

dry=0
draft=0
push=0
split=0
messages=()

while (($#)); do
  case "$1" in
    --dry|-dry) dry=1; shift ;;
    --draft|-draft) draft=1; shift ;;
    --push|-push) push=1; shift ;;
    --split|-split) split=1; shift ;;
    --) shift; messages+=("$@"); break ;;
    *) messages+=("$1"); shift ;;
  esac
done

msg="${messages[*]:-}"
msg="${msg#"${msg%%[![:space:]]*}"}"
msg="${msg%"${msg##*[![:space:]]}"}"

if [[ -z "$msg" ]]; then
  echo "Missing commit message" >&2
  exit 1
fi

git rev-parse --is-inside-work-tree >/dev/null

changed_files() {
  git status --porcelain | sed -E 's/^...//' | sed -E 's/^.* -> //'
}

mapfile -t changed < <(changed_files)
if ((${#changed[@]} == 0)); then
  echo "∅ nothing to commit"
  exit 0
fi

if ((dry || draft)); then
  mode="Would"
  ((draft)) && mode="Draft would"
  echo "$mode stage: ${#changed[@]} files"
  echo "$mode commit: $msg"
  ((push)) && echo "$mode push current branch"
  exit 0
fi

scope_of() {
  [[ "$1" =~ ^[a-z]+\(([^)]+)\): ]] && echo "${BASH_REMATCH[1]}" || true
}

matches_scope() {
  local path="${1//\\//}"
  local scope="$2"
  path="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
  scope="$(printf '%s' "$scope" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$scope" || "$path" == "$scope" || "$path" == "$scope/"* || "$path" == *"/$scope/"* || "$path" == *"$scope"* ]]
}

push_current_branch() {
  branch="$(git branch --show-current)"
  if [[ -z "$branch" ]]; then
    echo "x cannot push in detached HEAD"
    exit 1
  fi
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git push
  else
    git push --set-upstream origin "$branch"
  fi
}

if ((split)); then
  git reset -q
  mapfile -t commit_messages < <(printf '%s\n' "$msg" | sed '/^[[:space:]]*$/d')
  for i in "${!commit_messages[@]}"; do
    one="${commit_messages[$i]}"
    scope="$(scope_of "$one")"
    mapfile -t remaining < <(changed_files)
    matches=()
    for file in "${remaining[@]}"; do
      if matches_scope "$file" "$scope"; then matches+=("$file"); fi
    done
    if ((${#matches[@]} == 0 && i == ${#commit_messages[@]} - 1)); then
      matches=("${remaining[@]}")
    fi
    ((${#matches[@]} == 0)) && continue
    git add -- "${matches[@]}"
    git diff --cached --quiet && continue
    git commit -m "$one"
  done
else
  git add -A
  if git diff --cached --quiet; then
    echo "∅ nothing to commit"
    exit 0
  fi
  git commit -m "$msg"
fi

((push)) && push_current_branch
