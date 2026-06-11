# 16. Staging and Production Strategy

## Goal

운영 배포 전에 staging 환경에서 먼저 설정, 이미지, smoke test, restore rehearsal을 검수합니다.

## Environment Separation

| Area | Staging | Production |
| --- | --- | --- |
| Inventory | `infra/onprem/inventory.staging.ini` | `infra/onprem/inventory.production.ini` |
| Vault | `infra/onprem/vault.staging.yml` | `infra/onprem/vault.production.yml` |
| Deploy directory | `/opt/devops-consulting-springboot-staging` | `/opt/devops-consulting-springboot` |
| Container prefix | `consulting-staging` | `consulting` |
| HTTP port | Customer-defined, for example `18080` | Customer-defined, for example `8080` |
| Observability ports | Local-only, staging-specific ports when sharing one host | Local-only production ports |

## Prepare Files

```bash
cd infra/onprem

cp inventory.staging.example.ini inventory.staging.ini
cp inventory.production.example.ini inventory.production.ini

cp vault.example.yml vault.staging.yml
cp vault.example.yml vault.production.yml
```

Set staging values:

```yaml
deploy_environment: "staging"
container_name_prefix: "consulting-staging"
spring_profiles_active: "staging"
app_http_port: "18080"
app_direct_port: "18081"
postgres_port: "15432"
grafana_port: "13000"
prometheus_port: "19090"
alertmanager_port: "19093"
loki_port: "13100"
```

Set production values:

```yaml
deploy_environment: "production"
container_name_prefix: "consulting"
spring_profiles_active: "prod"
app_http_port: "8080"
app_direct_port: "8081"
postgres_port: "5432"
grafana_port: "3000"
prometheus_port: "9090"
alertmanager_port: "9093"
loki_port: "3100"
```

Encrypt each vault file before handover:

```bash
ansible-vault encrypt vault.staging.yml
ansible-vault encrypt vault.production.yml
```

## Deploy

Staging:

```bash
ansible-playbook -i inventory.staging.ini playbook.yml \
  -e "vault_file=$PWD/vault.staging.yml" \
  -e "project_dir=/opt/devops-consulting-springboot-staging" \
  --ask-pass --ask-become-pass --ask-vault-pass
```

Production:

```bash
ansible-playbook -i inventory.production.ini playbook.yml \
  -e "vault_file=$PWD/vault.production.yml" \
  -e "project_dir=/opt/devops-consulting-springboot" \
  --ask-pass --ask-become-pass --ask-vault-pass
```

## GitHub Actions Environments

Create two GitHub Environments:

- `staging`
- `production`

Set `ONPREM_DEPLOY_DIR` separately:

| Environment | Secret |
| --- | --- |
| `staging` | `/opt/devops-consulting-springboot-staging` |
| `production` | `/opt/devops-consulting-springboot` |

Manual deploys can choose `staging` or `production` from the workflow dispatch input. Automatic deploys after `main` CI success use `production`.

## Verification Order

1. Deploy to staging
2. Run `./ops/smoke-test.sh`
3. Run `./ops/backup-postgres.sh`
4. Run `./ops/restore-rehearsal.sh --force`
5. Promote the same commit/image to production
