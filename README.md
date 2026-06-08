# On-premise DevOps Consulting Delivery Kit

이 프로젝트는 수동 배포, 모니터링 부재, 로그 추적 어려움, 장애 대응 절차 미흡을 가진 가상의 고객사를 대상으로 오픈소스 DevOps 도구를 활용해 운영 환경을 개선하는 컨설팅형 포트폴리오입니다.

이 저장소는 포트폴리오 공개용 버전이며 실제 서버 접속 정보, 비밀번호, 토큰, 운영 데이터, 백업 파일은 포함하지 않습니다. 배포 시에는 `.env.example`을 기준으로 환경에 맞는 `.env`를 별도로 생성해야 합니다.

1차 배포 대상은 비용이 들지 않는 온프레미스 Linux 서버입니다. AWS와 Terraform은 마지막 확장 단계로 분리했습니다.

중요한 전제: `app/`의 Spring Boot 서비스는 고객사 애플리케이션을 대신하는 샘플 워크로드입니다. 이 포트폴리오의 핵심 산출물은 애플리케이션 기능 개발이 아니라 서버 구성, 배포 자동화, 모니터링/로그/알림, 백업/복구, 운영 문서입니다.

## Consulting Scope

실제 DevOps 컨설팅 실무에 맞춰 범위를 다음처럼 나눴습니다.

| In Scope | Out of Scope |
| --- | --- |
| 현행 운영 문제 진단 | 고객사 비즈니스 기능 개발 |
| 온프렘 서버 표준 구성 | 프론트엔드 화면 개발 |
| Docker Compose 기반 실행 환경 | 백엔드 도메인 로직 개발 |
| Nginx reverse proxy | 고객사 소스코드 리팩터링 |
| CI/CD 파이프라인 템플릿 | 제품 기획 |
| Prometheus/Grafana/Loki/Alertmanager | 장기 24/7 운영 대행 |
| 백업/복구/Runbook/인수인계 문서 |  |

## Customer Scenario

가상의 고객사는 이미 API 서비스를 보유하고 있지만 배포와 운영은 담당자 경험에 의존하고 있습니다.

| Area | Before | After |
| --- | --- | --- |
| Deployment | 서버 SSH 접속 후 수동 배포 | CI 성공 후 self-hosted runner 기반 자동 배포 |
| Runtime | 애플리케이션 단독 실행 | Docker Compose 기반 표준 실행 환경 |
| Monitoring | 담당자가 서버에 접속해 상태 확인 | Prometheus + Grafana 대시보드 |
| Logging | 서버 내부 로그 파일 직접 확인 | Loki + Promtail 기반 중앙 로그 조회 |
| Alerting | 장애를 사용자가 먼저 발견 | Alertmanager 기반 장애 알림 정책 |
| Handover | 담당자 경험에 의존 | Runbook, 운영 가이드, 인수인계 문서 |

## Architecture

```text
Customer Git Repository or Image Registry
  |
  | source push / image publish
  v
GitHub Actions
  |
  | build / test / image publish
  v
On-premise Linux Server
  |
  +--> Nginx --> Customer Application --> PostgreSQL
  |
  +--> Prometheus --> Grafana
  |
  +--> Promtail --> Loki --> Grafana
  |
  +--> Alertmanager
```

## Tech Stack

| Category | Stack |
| --- | --- |
| Sample Workload | Java 17, Spring Boot, Gradle |
| App Contract | Docker image, environment variables, health endpoint, log path |
| Persistence | PostgreSQL |
| Metrics | Prometheus-compatible endpoint |
| Runtime | On-premise Linux, Docker, Docker Compose |
| Reverse Proxy | Nginx |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus, Grafana |
| Logging | Loki, Promtail |
| Alerting | Alertmanager |
| Server Automation | Ansible |
| Operations | Smoke test, backup/restore scripts, Runbook |
| Future Cloud Extension | Terraform, AWS EC2, VPC, Security Group |

## Local Quick Start

```bash
cd devops-consulting-springboot
docker compose up -d --build
```

| Service | URL |
| --- | --- |
| Spring Boot via Nginx | http://localhost:8080 |
| Spring Boot direct | http://localhost:8081 |
| Actuator health | http://localhost:8081/actuator/health |
| Prometheus metrics | http://localhost:8081/actuator/prometheus |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 |
| Loki | http://localhost:3100 |
| Alertmanager | http://localhost:9093 |

Grafana 계정과 데이터베이스 계정은 `.env.example`을 복사한 뒤 각 환경에 맞게 직접 설정합니다. 로컬 포트가 이미 사용 중이면 `docker-compose.yml`의 포트 매핑을 바꾸면 됩니다.

## On-premise Quick Start

온프렘 서버 또는 개인 VM에 배포할 때는 Ansible을 사용합니다.

```bash
cd infra/onprem
cp inventory.example.ini inventory.ini
vi inventory.ini
ansible-playbook -i inventory.ini playbook.yml
```

배포 후 확인:

```bash
curl http://YOUR_SERVER_IP:8080/api/health
```

## Sample API

샘플 API는 운영 환경 검증용입니다. 실제 고객사 적용 시에는 고객사 Docker image, health endpoint, log path, required env를 받아 같은 운영 플랫폼에 연결합니다.

```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/orders
curl -X POST http://localhost:8080/api/orders \
  -H 'Content-Type: application/json' \
  -d '{"customerName":"demo","productName":"keyboard","quantity":1}'
curl http://localhost:8080/api/error-test
```

## Repository Guide

```text
app/                 Spring Boot sample service
nginx/               Reverse proxy config
monitoring/          Prometheus config and alert rules
logging/             Loki and Promtail config
alertmanager/        Alertmanager config
grafana/             Provisioned datasources and dashboards
ops/                 Smoke test and backup/restore scripts
infra/onprem/        On-premise Ansible deployment
infra/terraform/     Future AWS infrastructure template
docs/                Consulting documents and handover materials
```

## Consulting Deliverables

- 고객사 문제 정의와 요구사항 정리
- 고객사 애플리케이션 인수 조건 정의
- 목표 아키텍처 제안
- CI/CD 파이프라인 설계
- 온프레미스 서버 배포 자동화
- 모니터링/로그/알림 구성
- 백업/복구 절차
- 장애 대응 Runbook
- 운영 안정화 설정
- 운영자 인수인계 문서
- 납품 검수 체크리스트

자세한 문서는 `docs/` 디렉터리에 정리했습니다.
