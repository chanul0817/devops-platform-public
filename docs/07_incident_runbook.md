# 07. Incident Runbook

## Case 1. Application Down

### Symptom

- Grafana `Application Availability`가 0으로 표시된다.
- Alertmanager에 `SpringBootAppDown` alert가 발생한다.

### Check

```bash
docker compose ps
docker compose logs app --tail=100
curl http://localhost:8081/actuator/health
```

### Recovery

```bash
docker compose restart app
docker compose ps
```

복구 후 Grafana와 Alertmanager에서 alert resolved 여부를 확인한다.

## Case 2. HTTP 5xx Increase

### Symptom

- `HighHttp5xxRate` alert 발생
- Grafana HTTP 5xx Rate 패널 증가

### Check

```bash
curl http://localhost:8080/api/error-test
```

Grafana Explore에서 다음 LogQL로 에러 로그를 확인한다.

```logql
{service="consulting-orders-api"} |= "ERROR"
```

### Recovery

- 최근 배포 변경 사항 확인
- DB 연결, 환경변수, 외부 API 상태 확인
- 필요 시 이전 이미지로 rollback

## Case 3. Database Connection Failure

### Check

```bash
docker compose ps postgres
docker compose logs postgres --tail=100
docker compose logs app --tail=100
```

### Recovery

```bash
docker compose restart postgres
docker compose restart app
```
