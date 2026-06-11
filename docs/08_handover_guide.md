# 08. Handover Guide

## Daily Operation

운영자는 다음 화면을 기본 확인 대상으로 사용합니다.

- Grafana `Spring Boot Observability` dashboard
- Prometheus target status
- Alertmanager alert list
- Grafana Explore의 Loki logs

## Common Commands

```bash
docker compose up -d --build
docker compose ps
docker compose logs app --tail=100
docker compose restart app
./ops/smoke-test.sh
./ops/backup-postgres.sh
docker compose down
```

서버 재부팅 후에는 Docker restart policy와 self-hosted runner service 상태를 확인합니다.

```bash
docker compose ps
systemctl status docker
systemctl status actions.runner.<owner>-<repo>.<runner-name>.service
```

## Configuration Ownership

| File | Owner | Purpose |
| --- | --- | --- |
| `docker-compose.yml` | Platform/DevOps | 로컬/단일 서버 실행 환경 |
| `monitoring/prometheus.yml` | Platform/DevOps | scrape target 관리 |
| `monitoring/alert-rules.yml` | Platform/DevOps + Backend | alert condition 관리 |
| `grafana/dashboards/` | Platform/DevOps | 운영 대시보드 |
| `logging/promtail-config.yml` | Platform/DevOps | 로그 수집 경로 |
| `ops/` | Platform/DevOps + Customer Ops | smoke test, backup, restore |
| `infra/onprem/` | Platform/DevOps | 온프렘 서버 자동 배포 |
| `infra/terraform/` | Platform/DevOps | 향후 AWS 확장 인프라 코드 |

## Handover Documents

- `00_real_world_devops_consulting.md`: 컨설팅 수행 흐름
- `11_customer_input_contract.md`: 고객사로부터 받아야 하는 정보
- `12_delivery_acceptance_checklist.md`: 납품 검수 체크리스트
- `13_backup_restore.md`: 백업/복구 절차
- `14_operations_hardening.md`: 운영 안정화와 남은 한계
- `15_secret_management.md`: 비밀값 관리와 Vault 암호화 절차
- `16_environment_strategy.md`: staging/production 분리 전략

## Next Steps

- 온프렘 서버에서 실제 실행 결과 캡처
- HTTPS와 도메인 적용
- AWS EC2 확장
- RDS 분리
- Argo CD와 Kubernetes 기반 GitOps 확장
