#!/usr/bin/env bash
set -euo pipefail

ORG="${GITHUB_ORG:-sygel-technology}"
DRY_RUN="${DRY_RUN:-true}"
EXCLUDED="${EXCLUDED_FORKS_FILE:-config/excluded-forks.txt}"

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "ERROR: Falta GH_TOKEN (secret ORG_TOKEN)." >&2
  exit 1
fi
if [[ "$DRY_RUN" != "true" && "$DRY_RUN" != "false" ]]; then
  echo "ERROR: DRY_RUN debe ser true o false." >&2
  exit 1
fi

summary() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '%s\n' "$1" >> "$GITHUB_STEP_SUMMARY"
  else
    printf '%s\n' "$1"
  fi
}

summary "## Sincronización de forks — ${ORG}"
summary "Modo: **$([[ "$DRY_RUN" == "true" ]] && echo 'simulación' || echo 'sincronización')**"
summary ""
summary "| Repositorio | Resultado |"
summary "| --- | --- |"

repos_file="$(mktemp)"
trap 'rm -f "$repos_file"' EXIT

if ! gh api --paginate \
  "orgs/${ORG}/repos?type=forks&per_page=100" \
  --jq '.[] | select(.fork == true and .archived == false) | .full_name' \
  > "$repos_file"; then
  echo "ERROR: No se han podido enumerar los forks de ${ORG}." >&2
  summary "| — | ❌ Error consultando GitHub |"
  exit 1
fi

mapfile -t repos < <(LC_ALL=C sort -u "$repos_file")
processed=0
synced=0
skipped=0
failed=0

for repo in "${repos[@]}"; do
  [[ -n "$repo" ]] || continue
  ((processed+=1))

  # Una línea exacta por fork; las líneas con # son comentarios.
  if [[ -f "$EXCLUDED" ]] && grep -Fqx -- "$repo" "$EXCLUDED"; then
    echo "OMITIDO: $repo (excluido)"
    summary "| \`$repo\` | ⏭️ Excluido |"
    ((skipped+=1))
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "SIMULACIÓN: gh repo sync $repo"
    summary "| \`$repo\` | 🔍 Se sincronizaría |"
    continue
  fi

  echo "Sincronizando: $repo"
  if gh repo sync "$repo"; then
    summary "| \`$repo\` | ✅ Sincronizado |"
    ((synced+=1))
  else
    echo "ERROR: $repo requiere revisión (divergencia, permisos o protección de rama)." >&2
    summary "| \`$repo\` | ❌ Requiere revisión |"
    ((failed+=1))
  fi
done

summary ""
summary "**Totales:** $processed forks encontrados; $synced sincronizados; $skipped excluidos; $failed con errores."
echo "Total: $processed; sincronizados: $synced; excluidos: $skipped; errores: $failed."

if (( failed > 0 )); then
  exit 1
fi
