# 03. Target Architecture

## Logical Architecture

```text
Client
  |
  v
On-premise Linux Server
  |
  v
Nginx Reverse Proxy
  |
  v
Customer Application Container
  |
  v
PostgreSQL

Customer Application --> /metrics or /actuator/prometheus --> Prometheus --> Grafana
Customer Application --> stdout or application.log --> Promtail --> Loki --> Grafana
Prometheus --> Alertmanager
```

## Design Decisions

| Decision | Reason |
| --- | --- |
| Docker Compose 우선 적용 | 신입 포트폴리오에서 재현성과 완성도를 높이기 위함 |
| 온프레미스 서버 우선 적용 | AWS 비용 없이 고객사 내부 서버 구축 시나리오를 보여주기 위함 |
| Ansible 사용 | 서버 패키지 설치, 프로젝트 복사, Compose 실행을 자동화 |
| 샘플 앱은 고객사 artifact 대체 | 실제 컨설팅에서는 고객사 image 또는 binary를 운영 환경에 연결 |
| Health/Metrics endpoint 계약 | 애플리케이션 상태와 메트릭을 표준 방식으로 확인 |
| Prometheus + Grafana | 오픈소스 기반 모니터링 표준 조합 |
| Loki + Promtail | 로그 수집 구성이 가볍고 Grafana와 통합이 쉬움 |
| Alertmanager | Prometheus alert rule과 자연스럽게 연동 |
| Smoke test와 backup script | 구축 후 검수와 인수인계에 필요한 운영 절차 제공 |
| Terraform | AWS 확장 단계의 인프라 생성 절차를 코드로 문서화 |

## Port Map

| Service | Port |
| --- | --- |
| Nginx | 8080 |
| Spring Boot direct | 127.0.0.1:8081 |
| PostgreSQL | 127.0.0.1:5432 |
| Grafana | 127.0.0.1:3000 |
| Prometheus | 127.0.0.1:9090 |
| Alertmanager | 127.0.0.1:9093 |
| Loki | 127.0.0.1:3100 |

운영 관측 도구는 기본적으로 loopback에만 bind합니다. 외부 접속이 필요하면 VPN, bastion, SSH tunnel을 통해 접근합니다.
