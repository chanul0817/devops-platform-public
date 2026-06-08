# 11. Customer Input Contract

DevOps 컨설팅 업무에서는 애플리케이션 기능 개발보다 실행 조건을 명확히 받는 것이 중요합니다. 아래 항목을 고객사에 요청합니다.

## Required Inputs

| Item | Example | Required |
| --- | --- | --- |
| Application image or artifact | `registry.example.com/order-api:1.0.0` | Yes |
| Application port | `8080` | Yes |
| Health endpoint | `/actuator/health`, `/health` | Yes |
| Metrics endpoint | `/actuator/prometheus`, `/metrics` | Optional |
| Log path | stdout, `/logs/application.log` | Yes |
| Environment variables | DB URL, DB user, DB password | Yes |
| Database requirement | PostgreSQL 16, schema migration method | Yes |
| External dependencies | Redis, object storage, SMTP, third-party API | Optional |
| Domain/TLS policy | `api.example.com`, wildcard certificate | Optional |
| Alert receiver | Slack webhook, Teams webhook, email | Optional |

## Not Required by Default

- 전체 프론트엔드/백엔드 소스코드
- 비즈니스 로직 수정 권한
- DB 내부 데이터 전체
- 운영자 개인 계정 비밀번호

단, CI/CD 파이프라인을 코드 저장소와 직접 연결해야 하는 경우에는 제한된 Git repository 권한이 필요할 수 있습니다.

## Acceptance Contract

고객사 애플리케이션은 다음 조건을 만족해야 운영 플랫폼에 연결할 수 있습니다.

- 컨테이너 또는 실행 artifact로 재현 가능해야 한다.
- health check endpoint를 제공해야 한다.
- 로그는 stdout 또는 합의된 파일 경로로 남겨야 한다.
- 환경별 설정은 env var 또는 외부 설정 파일로 주입 가능해야 한다.
- DB schema 변경 방식이 문서화되어야 한다.
