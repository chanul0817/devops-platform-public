# 15. Secret Management

이 프로젝트는 공개 저장소에 실제 비밀번호, webhook URL, token, SSH key를 저장하지 않습니다.

## Policy

| Item | Policy |
| --- | --- |
| Public repository | Only variable names and examples |
| Runtime secrets | Managed in `infra/onprem/vault.yml` |
| Git tracking | `vault.yml`, `.env`, backup files are ignored |
| Ansible output | `.env` rendering task uses `no_log: true` |
| Server handover | Customer receives secret rotation guide separately |

## Ansible Vault Workflow

Create a local vault file from the example:

```bash
cd infra/onprem
cp vault.example.yml vault.yml
vi vault.yml
```

Fill real values:

```yaml
app_image: "ghcr.io/<owner>/<image>:<tag>"

postgres_user: ""
postgres_password: ""

grafana_admin_user: ""
grafana_admin_password: ""

alert_slack_webhook_url: ""
alert_slack_channel: ""
```

`vault.yml` can also override non-secret runtime values from `.env.example`, such as ports, `BACKUP_SYNC_DIR`, `SMOKE_TEST_ATTEMPTS`, and `APP_IMAGE`. This allows the Ansible playbook to recreate the server `.env` without committing the real `.env` file.

Encrypt it:

```bash
ansible-vault encrypt vault.yml
```

Run deployment:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

Edit encrypted secrets later:

```bash
ansible-vault edit vault.yml
```

## Public Repository Check

Before making the repository public, scan for common secret patterns:

```bash
git grep -n "hooks.slack.com\\|discord.com/api/webhooks\\|BEGIN OPENSSH\\|GITHUB_TOKEN\\|POSTGRES_PASSWORD=.*[^[:space:]]\\|GRAFANA_ADMIN_PASSWORD=.*[^[:space:]]"
```

If a real secret was ever committed, remove it from the repository and rotate the secret immediately.
