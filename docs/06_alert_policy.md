# 06. Alert Policy

## Severity

| Severity | Meaning | Example |
| --- | --- | --- |
| critical | 즉시 대응 필요 | 애플리케이션 down |
| warning | 업무시간 내 확인 필요 | JVM heap 사용률 증가, 5xx 소량 발생 |
| info | 추세 관찰 | 트래픽 증가, 배포 완료 |

## Initial Policy

| Alert | Severity | First Action |
| --- | --- | --- |
| SpringBootAppDown | critical | 컨테이너 상태 확인 후 재시작 |
| HighHttp5xxRate | warning | Grafana logs에서 에러 스택 확인 |
| HighJvmHeapUsage | warning | 트래픽 증가 여부와 GC 추이 확인 |

## Notification Rule

- 동일 alert는 3시간마다 반복 알림을 보낸다.
- alert가 resolved되면 resolved notification을 보낸다.
- 야간 critical alert는 담당자에게 즉시 전달한다.

## Notification Channel

Alertmanager receiver는 `.env`의 webhook 설정으로 생성합니다. 공개 저장소에는 실제 webhook URL을 저장하지 않습니다.

```bash
ALERT_DISCORD_WEBHOOK_URL=
# or
ALERT_SLACK_WEBHOOK_URL=
```

설정 적용:

```bash
./ops/configure-alertmanager.sh
docker compose restart alertmanager
```

테스트 알림:

```bash
./ops/send-test-alert.sh
```

## Customer Customization

실제 고객사 적용 시 다음 기준을 함께 조정합니다.

- 업무시간/야간 알림 채널 분리
- 담당 팀별 receiver 분리
- 서비스별 threshold 조정
- 반복 알림 주기 조정
