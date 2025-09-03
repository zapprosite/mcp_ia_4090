#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/data/projetos/mcp"
# ajuste se o nome/namespace for outro
GITLAB_REPO="${1:-https://gitlab.com/zapprosite/mcp_ia_4090.git}"

cd "$REPO_DIR"

# 1) PAT com write_repository ou api
read -rsp "Cole o PAT do GitLab: " GITLAB_TOKEN; echo

# 2) Remoto gitlab
git remote remove gitlab 2>/dev/null || true
git remote add gitlab "$GITLAB_REPO"

# 3) Validação rápida do token
curl -fsS -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/user >/dev/null || {
  echo "TOKEN inválido ou sem escopo"; exit 1; }

# 4) Push usando o token uma ÚNICA vez
git push -u "https://oauth2:${GITLAB_TOKEN}@${GITLAB_REPO#https://}" main
git push     "https://oauth2:${GITLAB_TOKEN}@${GITLAB_REPO#https://}" --tags

unset GITLAB_TOKEN
echo "OK: enviado para GitLab remoto 'gitlab'."
