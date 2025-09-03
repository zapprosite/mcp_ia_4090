#!/usr/bin/env bash
set -Eeuo pipefail
REPO="/data/projetos/mcp"
GL_PATH_ENC="zapprosite%2Fmcp_ia_4090"   # namespace/repo URL-encoded
: "${GITLAB_TOKEN:?export GITLAB_TOKEN=... (api + read_repository + write_repository)}"

echo "1) Desprotegendo 'main' no GitLab..."
curl -fsS -X DELETE \
  -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "https://gitlab.com/api/v4/projects/${GL_PATH_ENC}/protected_branches/main" \
  || true

echo "2) Push forçado para 'main' do GitLab..."
cd "$REPO"
git push gitlab +main:main

echo "3) Reprotegendo 'main' (sem force-push)..."
curl -fsS -X POST \
  -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --data "name=main&push_access_level=40&merge_access_level=40" \
  "https://gitlab.com/api/v4/projects/${GL_PATH_ENC}/protected_branches" >/dev/null

echo "OK: main sincronizada e protegida novamente."
