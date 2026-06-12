# Backup / Standby Server

This directory prepares a separate Linux backup server for PostgreSQL dump files and uploaded files. It can also prepare the same server to become a PostgreSQL standby server.

The app server pushes backup artifacts to this server using `rsync` over SSH.

## Prepare

Create an SSH key on the app server:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/devops_backup -C "devops-platform-backup"
cat ~/.ssh/devops_backup.pub
```

Copy the inventory example:

```bash
cp inventory.example.ini inventory.ini
vi inventory.ini
```

Run the backup server playbook with the app server public key:

```bash
ansible-playbook -i inventory.ini playbook.yml \
  -e "backup_ssh_public_key='PASTE_APP_SERVER_PUBLIC_KEY'"
```

To prepare the server for the PostgreSQL standby phase, enable Docker setup:

```bash
ansible-playbook -i inventory.ini playbook.yml \
  -e "backup_ssh_public_key='PASTE_APP_SERVER_PUBLIC_KEY'" \
  -e "standby_enabled=true"
```

Validate the standby server base:

```bash
docker --version
docker compose version
ls -ld /opt/devops-postgres-standby
```

## App Server Settings

Set these values through `infra/onprem/vault.yml`:

```yaml
backup_remote_enabled: "true"
backup_remote_host: "BACKUP_SERVER_HOST"
backup_remote_user: "devopsbackup"
backup_remote_port: "22"
backup_remote_dir: "/srv/backups/devops-platform"
backup_remote_ssh_key: "/path/to/backup_private_key"
file_backup_source_dir: "/opt/devops-consulting-springboot/uploads"
```

Then run the on-premise playbook and test:

```bash
./ops/backup-postgres.sh
```

## Standby Extension

The standby phase adds PostgreSQL streaming replication on this server. This playbook only prepares Docker and the standby work directory first. Replication setup is performed after verifying SSH connectivity from the standby server to the primary server.
