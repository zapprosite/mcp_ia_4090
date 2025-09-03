#!/usr/bin/env bash
set -euo pipefail
REPO_URL="${1:-https://gitlab.com/zapprosite/mcp_ia_4090.git}"

read -rsp "Cole o PAT GitLab (escopo write_repository): " GITLAB_TOKEN; echo

# valida token
curl -fsS -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" https://gitlab.com/api/v4/user >/dev/null || {
  echo "PAT inválido ou sem escopo"; exit 1; }

TMP_REMOTE="gitlab_token"
git remote remove "${TMP_REMOTE}" 2>/dev/null || true
git remote add    "${TMP_REMOTE}" "https://oauth2:${GITLAB_TOKEN}@${REPO_URL#https://}"

git push -u "${TMP_REMOTE}" main
git push   "${TMP_REMOTE}" --tags

git remote remove "${TMP_REMOTE}"
unset GITLAB_TOKEN
echo "OK: push para ${REPO_URL}"
