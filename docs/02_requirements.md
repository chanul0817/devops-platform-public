# 02. Requirements

## Customer-provided Inputs

- 고객사는 실행 가능한 애플리케이션 artifact 또는 Docker image를 제공한다.
- 고객사는 서비스 포트, health endpoint, 로그 위치, 환경변수 목록을 제공한다.
- 고객사는 DB 종류, schema migration 방식, 백업 요구사항을 제공한다.
- 고객사는 알림을 받을 채널과 담당자를 제공한다.

## Functional Requirements

- 고객사 애플리케이션은 컨테이너 기반으로 실행되어야 한다.
- 개발자는 GitHub에 코드를 push하면 테스트와 이미지 빌드를 자동으로 수행할 수 있어야 한다.
- 운영자는 Grafana에서 애플리케이션 상태와 로그를 확인할 수 있어야 한다.
- 장애 조건이 발생하면 Alertmanager에서 알림을 생성해야 한다.
- 온프레미스 Linux 서버 배포를 위한 Ansible 자동화가 제공되어야 한다.
- smoke test와 DB backup/restore 절차가 제공되어야 한다.
- AWS 배포를 위한 Terraform 템플릿은 마지막 확장 단계로 분리되어야 한다.

## Non-functional Requirements

- 로컬 개발자는 `docker compose up -d --build` 명령으로 동일한 환경을 재현할 수 있어야 한다.
- 서버 구성, 인프라, 운영 도구 설정은 코드로 관리되어야 한다.
- 포트, 계정, 알림 URL 등 환경별 값은 설정으로 분리할 수 있어야 한다.
- 운영 인수인계를 위한 문서가 함께 제공되어야 한다.

## Acceptance Criteria

| Item | Criteria |
| --- | --- |
| API | `/api/health`, `/api/orders`, `/actuator/health` 응답 가능 |
| Metrics | Prometheus에서 `spring-boot-app` target이 UP 상태 |
| Dashboard | Grafana에서 HTTP 요청 수, JVM 메모리, 로그 확인 가능 |
| Logs | `/api/error-test` 호출 후 Loki에서 에러 로그 검색 가능 |
| Alerts | 앱 중지 또는 5xx 발생 시 Alertmanager alert 확인 가능 |
| Backup | `ops/backup-postgres.sh`로 DB backup 생성 가능 |
| Restore | `ops/restore-postgres.sh`로 복구 절차 설명 가능 |
| Handover | 납품 검수 체크리스트와 Runbook 제공 |
| On-prem | Ansible로 Linux 서버에 Docker Compose 스택 배포 가능 |
| Future AWS | Terraform으로 EC2, VPC, Security Group 계획 확인 가능 |
