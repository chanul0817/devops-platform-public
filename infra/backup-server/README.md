# Backup Server

This directory prepares a separate Linux backup server for PostgreSQL dump files and uploaded files.

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
