#!/usr/bin/env bash
set -Eeuo pipefail
REPO_URL="${1:-https://github.com/zapprosite/mcp_ia_4090.git}"
REPO_DIR="${2:-$PWD}"
TOKENV="$HOME/.config/mcp/git_tokens.env"

mkdir -p "$(dirname "$TOKENV")"; chmod 700 "$(dirname "$TOKENV")"
if [ -f "$TOKENV" ]; then source "$TOKENV"; fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  read -rsp "Cole seu github_pat_...: " GITHUB_TOKEN; echo
  umask 077; printf "export GITHUB_TOKEN='%s'\n" "$GITHUB_TOKEN" >"$TOKENV"; chmod 600 "$TOKENV"
fi

LOGIN="$(curl -fsS -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user \
         | sed -n 's/.*"login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -n "$LOGIN" ] || { echo "Token inválido (precisa Contents RW + Metadata R)."; exit 1; }
echo "GitHub OK: $LOGIN"

cd "$REPO_DIR"

# .gitignore com sudo tee (evita 'Permission denied' do redirecionamento)
sudo tee .gitignore >/dev/null <<'GI'
# pesos/modelos/artefatos grandes
**/*.gguf
**/*.safetensors
**/*.bin
**/*.pt
**/*.pth
**/*.tar
**/*.tgz
**/*.zip
hf_cache/
ollama_models/
models/
qdrant/storage/
# segredos e var. locais
.env
*.env
secrets/*.*
GI

git init -b main 2>/dev/null || true
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

git add -A
git -c user.name="zappro" -c user.email="zappro.ia@gmail.com" \
    commit -m "checkpoint $(date +%F_%H%M%S)" || true
TAG="checkpoint-$(date +%Y%m%d-%H%M%S)"; git tag -a "$TAG" -m "$TAG" || true

PUSH_URL="https://x-access-token:${GITHUB_TOKEN}@${REPO_URL#https://}"
git push -u "$PUSH_URL" main
git push "$PUSH_URL" --tags
echo "Done."
