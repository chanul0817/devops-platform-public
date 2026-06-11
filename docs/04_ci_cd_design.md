# 04. CI/CD Design

## Goal

기존 수동 배포 방식에서 발생하던 실수와 누락을 줄이기 위해 테스트, 이미지 빌드, 이미지 태그 관리, 온프렘 배포 단계를 파이프라인으로 분리합니다.

## Pipeline

```text
pull request
  |
  v
test + docker build validation
  |
  v
merge to main
  |
  v
CI success
  |
  v
deploy workflow
  |
  +--> image publish
  |
  +--> delivery package sync
  |
  v
deploy to on-premise server
  |
  v
smoke test
```

## CI Workflow

`.github/workflows/ci.yml`은 다음 작업을 수행합니다.

- Gradle 컨테이너에서 Spring Boot 테스트 실행
- Docker Buildx로 애플리케이션 이미지 빌드 검증

실제 고객사 적용 시에는 언어와 빌드 도구에 맞게 이 단계를 교체합니다. 컨설팅 산출물의 핵심은 고객사 build command를 파이프라인에 반영하고, 이미지 태그와 배포 절차를 표준화하는 것입니다.

## Deploy Workflow

`.github/workflows/deploy-onprem.yml`은 온프렘 네트워크 안에 설치된 GitHub Actions self-hosted runner에서 실행되는 CD 파이프라인입니다. GitHub-hosted runner가 고객사 내부 서버로 직접 SSH 접속하지 않고, 내부 runner가 로컬 배포를 수행하도록 구성했습니다.

트리거 방식:

- `main` 브랜치에 변경사항이 merge되면 `CI` workflow가 실행됨
- `CI` workflow가 성공한 경우에만 `Deploy to On-premise Server` workflow가 자동 실행됨
- 장애 대응이나 재배포가 필요할 때는 `workflow_dispatch`로 수동 실행 가능
- `concurrency`로 동일 온프렘 서버에 여러 배포가 동시에 겹치지 않도록 제한

배포 시 수행하는 작업:

- GitHub Actions에서 샘플 애플리케이션 이미지를 빌드하고 GHCR에 push
- `onprem` 라벨이 붙은 self-hosted runner가 배포 패키지 파일을 `/opt/devops-consulting-springboot`에 동기화
- 서버 `.env`의 `APP_IMAGE` 값을 새 이미지 태그로 갱신
- 서버에서는 `docker compose up -d --no-build --remove-orphans`로 실행하여 서버 내부 Gradle 빌드를 피하고 이미지 기반으로 배포
- 배포 후 `ops/smoke-test.sh`로 health/API/metrics endpoint를 검증
- smoke test 실패 시 이전 `APP_IMAGE`로 자동 rollback 후 배포 job은 실패 처리

필요한 GitHub Actions runner:

| Item | Description |
| --- | --- |
| Runner type | Self-hosted runner |
| Location | 온프렘 서버 또는 같은 내부망의 배포 서버 |
| Required labels | `self-hosted`, `Linux`, `onprem` |

필요한 GitHub Secrets:

| Secret | Description |
| --- | --- |
| `ONPREM_DEPLOY_DIR` | GitHub Environment별 배포 디렉터리. 예: staging은 `/opt/devops-consulting-springboot-staging`, production은 `/opt/devops-consulting-springboot` |

## Staging and Production

`workflow_dispatch` 실행 시 `staging` 또는 `production`을 선택할 수 있습니다. GitHub Environments를 사용해 환경별 `ONPREM_DEPLOY_DIR` secret과 승인 정책을 분리합니다.

Ansible 배포 설정은 `docs/16_environment_strategy.md`에 정리된 것처럼 환경별 inventory/vault 파일을 분리합니다.

## Future Improvement

- Blue-Green 또는 Rolling deployment
- AWS EC2 배포 workflow 활성화
- Argo CD 기반 GitOps 배포
