#!/usr/bin/env bash
set -euo pipefail
REPO="/data/projetos/mcp"

# edite se mudar nomes/paths:
GH_USER="zapprosite"
GH_REPO="mcp_ia_4090"
GL_NS="zapprosite"
GL_REPO="mcp_ia_4090"

: "${GITHUB_TOKEN:?export GITHUB_TOKEN=... (PAT do GitHub)}"
: "${GITLAB_TOKEN:?export GITLAB_TOKEN=... (PAT do GitLab com api+read_repository+write_repository)}"

cd "$REPO"

# 1) limpar remotos bagunçados
for r in origin gitlab gitlab_token; do git remote remove "$r" 2>/dev/null || true; done

# 2) origin -> GitHub (fetch/push)
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"

# 3) gitlab -> GitLab (só para espelhar)
git remote add gitlab "https://oauth2:${GITLAB_TOKEN}@gitlab.com/${GL_NS}/${GL_REPO}.git"

# 4) validar tokens rapidamente
echo -n "GitHub: "
curl -fsS -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/user \
 | grep -o '"login":[^,]*' || echo "NOK"
echo -n "GitLab: "
curl -fsS -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" https://gitlab.com/api/v4/user \
 | grep -o '"username":[^,]*' || echo "NOK"

# 5) alinhar local ao GitHub e espelhar no GitLab
git fetch origin main
git checkout -B main
git reset --hard origin/main
git push gitlab +main --force-with-lease
git push gitlab --tags

# 6) mostrar configuração final
echo; git remote -v
