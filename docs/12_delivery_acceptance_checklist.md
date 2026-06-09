# 12. Delivery Acceptance Checklist

납품 전 고객사와 함께 확인할 체크리스트입니다.

## Server and Network

| Check | Result |
| --- | --- |
| 대상 서버 OS와 Docker 버전 확인 |  |
| 필요한 inbound port만 공개 |  |
| DB 포트 외부 노출 차단 |  |
| Grafana/Prometheus/Alertmanager 접근 범위 제한 |  |
| Nginx reverse proxy route 확인 |  |

## Deployment

| Check | Result |
| --- | --- |
| Ansible playbook 재실행 가능 |  |
| `docker compose up -d` 재실행 가능 |  |
| 신규 이미지 태그 교체 배포 가능 |  |
| 배포 후 smoke test 통과 |  |
| smoke test 실패 시 이전 이미지 자동 rollback 확인 |  |
| 서버 재부팅 후 컨테이너 자동 복구 정책 확인 |  |
| rollback 절차 문서화 |  |

## Observability

| Check | Result |
| --- | --- |
| Prometheus target UP |  |
| Grafana dashboard 확인 |  |
| Loki에서 애플리케이션 로그 검색 가능 |  |
| 5xx 또는 app down alert 발생 확인 |  |
| Discord/Slack 등 외부 알림 채널 수신 확인 |  |
| alert resolved notification 확인 |  |

## Backup and Recovery

| Check | Result |
| --- | --- |
| PostgreSQL backup 파일 생성 |  |
| 정기 백업 timer 활성화 확인 |  |
| backup 파일 보관 위치 확인 |  |
| Backup Server로 DB dump 전송 확인 |  |
| 업로드 파일 외부 백업 동기화 확인 |  |
| restore 절차 dry-run 완료 |  |
| 복구 책임자와 연락 채널 확인 |  |

## Secret Management

| Check | Result |
| --- | --- |
| `.env`가 Git에 포함되지 않는지 확인 |  |
| `infra/onprem/vault.yml`이 Git에 포함되지 않는지 확인 |  |
| Ansible Vault로 DB/Grafana/Webhook secret 주입 확인 |  |
| 공개 저장소 secret scan 완료 |  |

## Handover

| Check | Result |
| --- | --- |
| 운영 명령어 전달 |  |
| 장애 대응 Runbook 전달 |  |
| 알림 정책 전달 |  |
| 계정/비밀값 변경 가이드 전달 |  |
| 향후 개선 항목 합의 |  |
