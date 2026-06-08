# 14. Operations Hardening

이 문서는 단일 온프렘 서버 환경에서 실제 운영에 가깝게 적용한 안정화 항목과 남은 한계를 정리합니다.

## Applied Controls

| Area | Control |
| --- | --- |
| Network exposure | Application만 외부 공개, Grafana/Prometheus/Alertmanager/Loki는 `127.0.0.1` bind |
| Access path | 운영 도구는 SSH tunnel 또는 VPN을 통해 접근 |
| Recovery | Compose 서비스에 `restart: unless-stopped` 적용 |
| Deployment | GitHub Actions self-hosted runner로 내부망 배포 |
| Image delivery | 서버에서 소스 빌드 대신 GHCR image pull |
| Container logs | Docker `json-file` log rotation 적용 |
| Resource guardrail | 주요 컨테이너에 CPU/memory limit 적용 |
| Metrics retention | Prometheus 보관 기간을 환경변수로 제어 |
| Alert delivery | Alertmanager에서 Discord/Slack webhook으로 장애 알림 전송 |
| Backup | PostgreSQL dump 생성, 비어 있는 백업 방지, retention cleanup |
| Scheduled backup | systemd timer로 정기 PostgreSQL backup 실행 |
| Restore | 복구 전 안전 백업, app stop, schema reset, restore, app restart |
| Deployment rollback | 새 이미지 smoke test 실패 시 이전 `APP_IMAGE`로 자동 rollback |

## Runtime Defaults

| Setting | Default |
| --- | --- |
| `OBSERVABILITY_BIND_ADDR` | `127.0.0.1` |
| `PROMETHEUS_RETENTION_TIME` | `7d` |
| `DOCKER_LOG_MAX_SIZE` | `10m` |
| `DOCKER_LOG_MAX_FILE` | `3` |
| `BACKUP_RETENTION_DAYS` | `7` |
| `BACKUP_SYNC_DIR` | Empty, optional external mount path |

## Verification Commands

```bash
cd /opt/devops-consulting-springboot
docker compose ps
docker compose config | grep -E "restart: unless-stopped|mem_limit|cpus"
docker inspect -f '{{.Name}} {{.HostConfig.RestartPolicy.Name}} {{.HostConfig.Memory}}' consulting-nginx consulting-springboot-app consulting-postgres
ss -tulpen | grep -E '8080|3000|9090|9093|3100'
./ops/backup-postgres.sh
systemctl list-timers devops-postgres-backup.timer
```

Expected network exposure:

```text
0.0.0.0:8080        Application
127.0.0.1:3000      Grafana
127.0.0.1:9090      Prometheus
127.0.0.1:9093      Alertmanager
127.0.0.1:3100      Loki
```

## Single Server Limitations

| Risk | Current State | Production Direction |
| --- | --- | --- |
| Server power off | All services stop | Multi-node or cloud HA |
| Disk failure | Local volumes can be lost | External backup storage, DB replica |
| Host resource exhaustion | Container limits reduce blast radius | Capacity monitoring, autoscaling |
| Deployment rollback | Smoke test failure triggers previous image rollback | Blue-Green or canary deployment |
| Secret management | `.env` based demo config | Ansible Vault, Vault, Secret Manager |
| TLS | Not configured in this demo | HTTPS reverse proxy and certificate automation |

## Next Production Steps

1. Move PostgreSQL backups to external storage such as NAS, S3, or MinIO.
2. Add scheduled backup through systemd timer or cron.
3. Add HTTPS and domain-based routing.
4. Move secrets to Ansible Vault or a secret manager.
5. Split production and staging environments.
6. Add Blue-Green or canary deployment.
