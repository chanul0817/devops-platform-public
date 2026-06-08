# 05. Monitoring and Logging Design

## Metrics

샘플 앱은 Spring Boot Actuator와 Micrometer를 사용해 `/actuator/prometheus` 엔드포인트로 메트릭을 노출합니다. 실제 고객사 앱은 Prometheus-compatible endpoint 또는 exporter를 통해 같은 방식으로 연결합니다. Prometheus는 15초마다 해당 엔드포인트를 scrape합니다.

주요 확인 항목:

- 애플리케이션 UP/DOWN
- HTTP 요청 수
- HTTP 5xx 비율
- JVM heap memory 사용률
- API endpoint별 요청 추이

## Logs

샘플 Spring Boot 앱은 파일 로그를 `/logs/application.log`에 기록합니다. 실제 고객사 앱은 stdout 로그 또는 합의된 파일 경로를 사용합니다. Docker volume을 통해 Promtail이 해당 로그를 읽고 Loki로 전송합니다.

Grafana에서는 다음 쿼리로 로그를 확인할 수 있습니다.

```logql
{service="consulting-orders-api"}
```

에러 테스트:

```bash
curl http://localhost:8080/api/error-test
```

## Alert Rules

| Alert | Condition |
| --- | --- |
| `SpringBootAppDown` | Prometheus scrape target이 1분 이상 down |
| `HighHttp5xxRate` | 2분 내 HTTP 5xx 응답 발생 |
| `HighJvmHeapUsage` | JVM heap 사용률 80% 이상 3분 지속 |

## Alert Delivery

현재 로컬 구성은 `host.docker.internal:9099/alerts`로 webhook을 보냅니다. 실제 고객사 환경에서는 Slack, Teams, Discord, 사내 webhook으로 변경합니다.

## Validation

납품 전 다음 항목을 고객사와 함께 확인합니다.

- Prometheus target이 UP인지 확인
- Grafana dashboard에서 요청 수와 JVM/애플리케이션 메트릭 확인
- Loki에서 error log 검색
- 앱 중지 또는 `/api/error-test` 호출로 alert 발생 확인
- resolved notification 확인
