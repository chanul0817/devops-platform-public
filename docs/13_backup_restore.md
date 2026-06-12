# 13. Backup and Restore

## Backup Policy

| Item | Policy |
| --- | --- |
| Target | PostgreSQL database |
| Frequency | Daily for demo, customer-defined for production |
| Retention | 7 days for demo |
| Storage | Local backup directory, optional mount path, optional Backup Server over SSH |
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

## Backup Server Sync

비용이 드는 Object Storage 대신 별도 Linux 서버를 Backup Server로 두고 `rsync over SSH`로 DB dump와 업로드 파일을 전송할 수 있습니다.

```text
App Server
  +--> ./backups/orders_*.sql
  +--> uploaded files directory
        |
        v
Backup Server:/srv/backups/devops-platform
```

앱 서버 `.env` 또는 Ansible Vault에 다음 값을 설정합니다.

```bash
BACKUP_REMOTE_ENABLED=true
BACKUP_REMOTE_HOST=BACKUP_SERVER_HOST
BACKUP_REMOTE_USER=devopsbackup
BACKUP_REMOTE_PORT=22
BACKUP_REMOTE_DIR=/srv/backups/devops-platform
BACKUP_REMOTE_SSH_KEY=/path/to/backup_private_key
FILE_BACKUP_SOURCE_DIR=/opt/devops-consulting-springboot/uploads
```

Backup Server 초기 준비는 `infra/backup-server/`의 Ansible playbook으로 수행합니다.

파일 백업 경로가 설정되어 있으면 Ansible이 해당 디렉터리를 생성합니다. 실제 검수에서는 헬스체크 스크립트가 `.backup-healthcheck` sentinel 파일을 만들고, 백업 서버의 `files/current/`까지 동기화되는지 확인합니다.

```bash
./ops/check-backup-health.sh
```

성공 기준:

1. 로컬 DB dump 파일이 비어 있지 않음
2. 백업 서버 `db/` 경로에 동일한 dump 파일이 존재함
3. 파일 백업 경로가 설정된 경우 백업 서버 `files/current/.backup-healthcheck`가 존재함

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

정기 백업 서비스에는 실패 알림이 연결됩니다. `devops-postgres-backup.service`가 실패하면 `devops-postgres-backup-failure-alert.service`가 Alertmanager로 `PostgreSQLBackupFailed` 알림을 보냅니다.

```bash
systemctl status devops-postgres-backup-failure-alert.service --no-pager
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

## Restore Rehearsal

복구 검수는 백업 파일이 실제로 복구 가능한지 확인하는 절차입니다. 이 스크립트는 checkpoint backup을 만들고, marker order를 추가한 뒤, checkpoint backup으로 restore해서 marker가 사라졌는지 확인합니다.

운영 데이터베이스를 되돌리는 작업이므로 고객사 승인 후 실행합니다.

```bash
./ops/restore-rehearsal.sh --force
```

자동화에서 실행할 때는 다음처럼 승인 값을 환경 변수로 전달할 수 있습니다.

```bash
CONFIRM_RESTORE_REHEARSAL=yes ./ops/restore-rehearsal.sh
```

성공 기준:

1. checkpoint backup 파일이 생성됨
2. marker order가 restore 전에는 조회됨
3. restore 후 smoke test가 통과함
4. marker order가 restore 후에는 조회되지 않음

## Future Improvement

- backup 암호화
- staging 환경에서 정기 restore rehearsal 자동화
