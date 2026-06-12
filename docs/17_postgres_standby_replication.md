# 17. PostgreSQL Standby Replication

## Goal

The backup server can be extended into a standby DB server.

```text
Primary server
  App + Primary PostgreSQL
        |
        | PostgreSQL streaming replication
        v
Standby server
  Backup storage + PostgreSQL Replica
```

This is not automatic failover yet. The first target is standby replication and a manual promotion runbook.

## Phase 1: Prepare Standby Server

The standby server needs Docker and a dedicated project directory.

```bash
cd infra/backup-server

ansible-playbook -i inventory.ini playbook.yml \
  -e "backup_ssh_public_key='PASTE_APP_SERVER_PUBLIC_KEY'" \
  -e "standby_enabled=true"
```

Validate on the standby server:

```bash
docker --version
docker compose version
ls -ld /opt/devops-postgres-standby
```

## Phase 2: Verify Network Path

The primary server currently exposes PostgreSQL only on `127.0.0.1`. Keep that boundary and connect the standby server through an SSH tunnel.

```text
Standby PostgreSQL
  -> local tunnel port
  -> SSH tunnel
  -> Primary server 127.0.0.1:5432
```

Before configuring replication, verify SSH from the standby server to the primary server.

## Phase 3: Configure Replication

1. Create a replication role on the primary DB.
2. Create an SSH tunnel service on the standby server.
3. Run `pg_basebackup` from the standby server.
4. Start the standby PostgreSQL container.
5. Verify replay status and read-only mode.

## Future Improvement

- Automatic failover with Patroni or repmgr
- App failover through HAProxy or keepalived
- Separate backup storage and standby DB roles for larger production environments
