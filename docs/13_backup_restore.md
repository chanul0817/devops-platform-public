# 13. Backup and Restore

## Backup Policy

| Item | Policy |
| --- | --- |
| Target | PostgreSQL database |
| Frequency | Daily for demo, customer-defined for production |
| Retention | 7 days for demo |
| Storage | Local backup directory, optional sync directory for NAS/S3/MinIO mount |
| Verification | Restore dry-run before handover |

## Backup

```bash
./ops/backup-postgres.sh
```

기본 backup directory는 `./backups`입니다. 백업은 임시 파일로 먼저 생성한 뒤, 비어 있지 않은 dump가 만들어졌을 때만 최종 파일로 이동합니다.

`BACKUP_RETENTION_DAYS` 값으로 오래된 백업 파일을 정리합니다. 기본값은 7일입니다.

```bash
BACKUP_RETENTION_DAYS=14 ./ops/backup-postgres.sh
```

`BACKUP_SYNC_DIR`를 지정하면 생성된 백업 파일을 추가 디렉터리로 복사합니다. 이 디렉터리는 NAS, NFS, MinIO mount, rclone mount처럼 외부 저장소로 연결할 수 있습니다.

```bash
BACKUP_SYNC_DIR=/mnt/company-backups/devops-platform ./ops/backup-postgres.sh
```

## Scheduled Backup

온프렘 서버에서는 `systemd timer`로 정기 백업을 등록합니다. 기본 스케줄은 매일 03:00입니다.

```bash
cd /opt/devops-consulting-springboot
sudo ./ops/install-backup-timer.sh
systemctl list-timers devops-postgres-backup.timer
```

즉시 실행 검수:

```bash
sudo systemctl start devops-postgres-backup.service
sudo journalctl -u devops-postgres-backup.service -n 50 --no-pager
ls -lh backups/
```

## Restore

```bash
./ops/restore-postgres.sh --force ./backups/orders_YYYYmmdd_HHMMSS.sql
```

복구 전에는 현재 데이터가 덮어써질 수 있으므로 고객사 승인 후 실행합니다. `--force`를 생략하면 destructive restore 경고만 출력하고 종료합니다.

복구 절차:

1. 현재 DB를 `./backups/*_pre_restore_*.sql`로 안전 백업
2. 애플리케이션 컨테이너 중지
3. PostgreSQL `public` schema 초기화
4. 지정한 backup SQL restore
5. 복구된 table count 확인
6. 애플리케이션 컨테이너 재기동

자동화에서 실행할 때는 다음처럼 승인 값을 환경 변수로 전달할 수 있습니다.

```bash
CONFIRM_RESTORE=yes ./ops/restore-postgres.sh ./backups/orders_YYYYmmdd_HHMMSS.sql
```

## Future Improvement

- backup 암호화
- 정기 restore rehearsal 자동화
