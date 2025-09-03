#!/usr/bin/env bash
set -euo pipefail
cd /data/projetos/mcp
git fetch origin main >/dev/null 2>&1 || true
git fetch gitlab main >/dev/null 2>&1 || true
echo "LOCAL HEAD:     $(git rev-parse --short HEAD || true)"
echo "GITHUB main:    $(git ls-remote origin -h refs/heads/main | awk '{print substr($1,1,7)}')"
echo "GITLAB main:    $(git ls-remote gitlab -h refs/heads/main | awk '{print substr($1,1,7)}')"
echo
echo "Divergência vs GitHub:"
git rev-list --left-right --count HEAD...origin/main 2>/dev/null || true
echo "Divergência vs GitLab:"
git rev-list --left-right --count HEAD...gitlab/main 2>/dev/null || true
