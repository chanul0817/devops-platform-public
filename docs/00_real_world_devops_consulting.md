# 00. Real-world DevOps Consulting Flow

이 문서는 실제 DevOps 컨설팅 업무 흐름에 맞춰 포트폴리오 범위를 정리한 것입니다.

## Engagement Flow

```text
1. Discovery
   - 현재 배포 방식, 서버 구성, 장애 이력, 로그 위치, 담당자 업무 방식 확인

2. Assessment
   - 수동 작업, 단일 장애점, 보안 노출, 백업 부재, 모니터링 공백 식별

3. Target Design
   - 서버 구조, 네트워크/포트 정책, 배포 방식, 관측성, 백업/복구 기준 정의

4. Implementation
   - Ansible, Docker Compose, Nginx, CI/CD, Prometheus, Grafana, Loki, Alertmanager 구성

5. Validation
   - smoke test, 장애 테스트, 로그/알림 테스트, 재배포 테스트, 복구 테스트

6. Handover
   - 운영 명령어, Runbook, 백업/복구 절차, 계정/비밀값 관리 기준 전달
```

## What the Consultant Receives

고객사가 항상 전체 소스코드를 제공한다고 가정하지 않습니다. 실무에서는 프로젝트 범위에 따라 다음 중 일부만 받습니다.

| Input | Example |
| --- | --- |
| Application artifact | Docker image, jar, binary, static build |
| Runtime contract | port, health endpoint, env vars, log path |
| Deployment access | Git repo access, registry access, SSH/VPN access |
| Infrastructure info | server IP, OS, firewall, domain, TLS policy |
| Operational needs | uptime target, backup policy, alert receiver |

## Portfolio Interpretation

`app/`은 고객사 애플리케이션을 대신하는 샘플입니다. 실제 포트폴리오 평가 포인트는 다음 산출물입니다.

- 요구사항을 운영 기준으로 번역한 문서
- 서버와 컨테이너 실행 환경 자동화
- Nginx reverse proxy와 포트 노출 정책
- CI/CD 또는 배포 스크립트
- Prometheus/Grafana/Loki/Alertmanager 구성
- 백업/복구와 장애 대응 Runbook
- 인수인계 체크리스트

## References

- AWS DevOps: infrastructure provisioning, deployment automation, monitoring and logging
- Google Cloud DORA capabilities: deployment automation, proactive failure notification, cloud infrastructure
- Microsoft DevOps: CI/CD, IaC, containers, monitoring
- Red Hat DevOps: CI/CD automation, monitoring across the application lifecycle, infrastructure as code
