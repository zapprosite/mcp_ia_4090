#!/usr/bin/env bash
set -Eeuo pipefail
: "${GITLAB_TOKEN:?export GITLAB_TOKEN=... (escopos: api, read_repository, write_repository)}"

PROJ="zapprosite%2Fmcp_ia_4090"   # namespace/repo URL-encoded
SRC="${1:-github-main}"
DST="${2:-main}"
TITLE="Sync ${SRC} -> ${DST} $(date +%F_%H%M%S)"

hdr=(-H "PRIVATE-TOKEN: ${GITLAB_TOKEN}")

# 1) Existe MR aberto?
MR_JSON="$(curl -fsS "${hdr[@]}" \
  "https://gitlab.com/api/v4/projects/${PROJ}/merge_requests?state=opened&source_branch=${SRC}&target_branch=${DST}")" || MR_JSON="[]"

# pega o primeiro iid (sem jq)
IID="$(printf '%s\n' "$MR_JSON" | sed -n 's/.*"iid":[[:space:]]*\([0-9]\+\).*/\1/p;q')"

# 2) Se não existir, cria
if [ -z "${IID}" ]; then
  CREATE="$(curl -fsS -X POST "${hdr[@]}" \
    --data-urlencode "source_branch=${SRC}" \
    --data-urlencode "target_branch=${DST}" \
    --data-urlencode "title=${TITLE}" \
    "https://gitlab.com/api/v4/projects/${PROJ}/merge_requests")"
  IID="$(printf '%s\n' "$CREATE" | sed -n 's/.*"iid":[[:space:]]*\([0-9]\+\).*/\1/p')"
fi

[ -n "${IID}" ] || { echo "Falha ao obter/criar MR."; exit 1; }
echo "MR IID=${IID} -> abrir: https://gitlab.com/zapprosite/mcp_ia_4090/-/merge_requests/${IID}"

# 3) Merge (remove branch de origem)
curl -fsS -X PUT "${hdr[@]}" \
  --data "should_remove_source_branch=true" \
  "https://gitlab.com/api/v4/projects/${PROJ}/merge_requests/${IID}/merge" >/dev/null

echo "Merge OK. ${SRC} -> ${DST}."
