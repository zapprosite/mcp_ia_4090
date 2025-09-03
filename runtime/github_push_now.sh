#!/usr/bin/env bash
set -Eeuo pipefail
REPO_URL="${1:-https://github.com/zapprosite/mcp_ia_4090.git}"   # pode passar outro na chamada
REPO_DIR="${2:-$PWD}"                                            # diretório atual por padrão
TOKENV="$HOME/.config/mcp/git_tokens.env"

# --- token ---
mkdir -p "$(dirname "$TOKENV")"; chmod 700 "$(dirname "$TOKENV")"
if [ -f "$TOKENV" ]; then
  # shellcheck disable=SC1090
  source "$TOKENV"
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  read -rsp "Cole seu github_pat_...: " GITHUB_TOKEN; echo
  umask 077
  {
    echo "export GITHUB_TOKEN='$GITHUB_TOKEN'"
  } >"$TOKENV"
  chmod 600 "$TOKENV"
fi

# --- valida token sem jq ---
LOGIN="$(curl -fsS -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user \
         | sed -n 's/.*"login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -n "$LOGIN" ] || { echo "Token inválido/sem permissão (need Contents RW + Metadata R)."; exit 1; }
echo "GitHub OK: $LOGIN"

# --- .gitignore mínimo (não subir pesos/segredos) ---
cd "$REPO_DIR"
cat > .gitignore <<'GI'
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

# --- init + commit + tag ---
git init -b main 2>/dev/null || true
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

git add -A
git -c user.name="zappro" -c user.email="zappro.ia@gmail.com" \
    commit -m "checkpoint $(date +%F_%H%M%S)" || true
TAG="checkpoint-$(date +%Y%m%d-%H%M%S)"
git tag -a "$TAG" -m "$TAG" || true

# --- push usando token na URL (não persiste no config) ---
PUSH_URL="https://x-access-token:${GITHUB_TOKEN}@${REPO_URL#https://}"
git push -u "$PUSH_URL" main
git push "$PUSH_URL" --tags

echo "Done."
