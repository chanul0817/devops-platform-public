#!/usr/bin/env sh
set -eu

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

pass() {
  echo "OK: $*"
}

warn() {
  echo "WARN: $*" >&2
}

check_not_tracked() {
  path="$1"
  if git ls-files --error-unmatch "$path" >/dev/null 2>&1; then
    fail "$path is tracked by Git"
  else
    pass "$path is not tracked by Git"
  fi
}

check_ignored() {
  path="$1"
  if git check-ignore -q "$path"; then
    pass "$path is ignored by Git"
  else
    fail "$path is not ignored by Git"
  fi
}

check_not_tracked ".env"
check_not_tracked "infra/onprem/vault.yml"
check_not_tracked "infra/onprem/vault.staging.yml"
check_not_tracked "infra/onprem/vault.production.yml"
check_not_tracked "backups/example.sql"

check_ignored ".env"
check_ignored "infra/onprem/vault.yml"
check_ignored "infra/onprem/vault.staging.yml"
check_ignored "infra/onprem/vault.production.yml"
check_ignored "infra/onprem/inventory.staging.ini"
check_ignored "infra/onprem/inventory.production.ini"
check_ignored "backups/example.sql"

if [ -f "infra/onprem/vault.yml" ]; then
  first_line="$(sed -n '1p' infra/onprem/vault.yml)"
  case "$first_line" in
    '$ANSIBLE_VAULT;'*)
      pass "infra/onprem/vault.yml is encrypted with Ansible Vault"
      ;;
    *)
      warn "infra/onprem/vault.yml exists but is not encrypted"
      warn "Run: ansible-vault encrypt infra/onprem/vault.yml"
      ;;
  esac
else
  warn "infra/onprem/vault.yml does not exist on this machine"
fi

P1='hooks.slack.com/'"services/[A-Za-z0-9]"
P2='discord.com/api/'"webhooks/[0-9]"
P3='BEGIN'" OPENSSH"
P4='PRIVATE'" KEY"
P5='GITHUB'"_TOKEN=[^[:space:]]"
P6='gh'"p_"
P7='github'"_pat_"
SECRET_PATTERN="${P1}\\|${P2}\\|${P3}\\|${P4}\\|${P5}\\|${P6}\\|${P7}"

if git grep -n "${SECRET_PATTERN}" -- . \
  ':(exclude)ops/check-secret-hygiene.sh' \
  ':(exclude)docs/15_secret_management.md' >/dev/null; then
  fail "tracked files contain possible secret patterns"
else
  pass "tracked files do not contain common secret patterns"
fi

if [ "$failures" -gt 0 ]; then
  echo "Secret hygiene check failed: ${failures} issue(s)" >&2
  exit 1
fi

echo "Secret hygiene check passed"
