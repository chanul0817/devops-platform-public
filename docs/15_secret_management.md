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

Before encryption, `vault.yml` is a local plain YAML file. It is still ignored by Git, but it should be encrypted before handover or repository sharing.

Run deployment while `vault.yml` is still plain YAML:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-pass --ask-become-pass
```

Encrypt it:

```bash
ansible-vault encrypt vault.yml
```

After encryption, run deployment with a vault password:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-pass --ask-become-pass --ask-vault-pass
```

Edit encrypted secrets later:

```bash
ansible-vault edit vault.yml
```

Check whether `vault.yml` is encrypted:

```bash
head -1 vault.yml
```

Encrypted vault files start with:

```text
$ANSIBLE_VAULT;1.1;AES256
```

## Public Repository Check

Before making the repository public, scan for common secret patterns:

```bash
./ops/check-secret-hygiene.sh
```

If a real secret was ever committed, remove it from the repository and rotate the secret immediately.
