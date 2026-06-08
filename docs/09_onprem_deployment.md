# 09. On-premise Deployment

## Purpose

AWS 비용 없이 고객사 내부 서버, 개인 VM, 사내 테스트 서버에 동일한 DevOps 운영 환경을 배포합니다. 이 단계가 본 프로젝트의 기본 배포 방식입니다.

## Target Server

| Item | Recommendation |
| --- | --- |
| OS | Ubuntu 22.04/24.04 또는 Debian 계열 |
| CPU | 2 vCPU 이상 |
| Memory | 4GB 이상 |
| Disk | 20GB 이상 |
| Network | 초기 구축용 SSH 접속 가능, 8080 포트 접근 가능 |
| Internet | Docker image pull, Gradle dependency download, GitHub Actions runner outbound 연결 가능 |

## Deployment Flow

```text
Local laptop
  |
  | ansible-playbook
  v
On-premise Linux server
  |
  +--> Docker / Docker Compose install
  +--> Deploy user Docker permission
  +--> Project files copy
  +--> .env create
  +--> docker compose up -d --build
```

초기 구축 이후 GitHub Actions CD는 `main` 브랜치의 CI가 성공했을 때 자동으로 실행됩니다.

```text
main merge
  |
  v
CI success
  |
  v
Build and push application image to GHCR
  |
  v
Self-hosted runner inside on-premise network
  |
  +--> Sync delivery package files
  +--> Update APP_IMAGE in .env
  +--> docker compose up -d --no-build --remove-orphans
```

즉 GitHub-hosted runner가 고객사 내부 서버로 SSH 접속하지 않습니다. 온프렘 서버 또는 같은 내부망에 설치된 self-hosted runner가 GitHub로 outbound 연결을 맺고, 배포 작업을 내부에서 실행합니다.

## Commands

대상 서버에 Docker가 아직 없다면 Docker 공식 APT 저장소로 설치합니다.

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg git rsync
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

```bash
cd infra/onprem
cp inventory.example.ini inventory.ini
vi inventory.ini
ansible-playbook -i inventory.ini playbook.yml
```

sudo 비밀번호가 필요한 서버:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

Ansible 실행 후 GitHub repository의 self-hosted runner를 서버에 설치합니다.

```text
GitHub repository
  -> Settings
  -> Actions
  -> Runners
  -> New self-hosted runner
  -> Linux
```

GitHub 화면에 표시되는 명령어를 서버에서 실행하고, runner label에 `onprem`을 추가합니다. runner 설치 후 현재 사용자가 Docker group 권한을 새로 받도록 SSH 재접속하거나 runner 서비스를 재시작합니다.

## Verification

```bash
curl http://YOUR_SERVER_IP:8080/api/health
curl http://YOUR_SERVER_IP:8080/api/orders
curl http://YOUR_SERVER_IP:8080/api/error-test
```

서버 내부 검증:

```bash
cd /opt/devops-consulting-springboot
./ops/smoke-test.sh
```

CD 검증:

```bash
cd /opt/devops-consulting-springboot
grep APP_IMAGE .env
docker compose ps
```

`APP_IMAGE`가 `ghcr.io/...:<commit-sha>` 형식이면 GitHub Actions CD가 이미지 기반 배포까지 완료된 상태입니다.

재부팅 복구 검증:

```bash
cd /opt/devops-consulting-springboot
docker compose config | grep -n "restart: unless-stopped"
docker inspect -f '{{.Name}} {{.HostConfig.RestartPolicy.Name}}' consulting-nginx consulting-springboot-app consulting-postgres
```

Docker service와 GitHub Actions self-hosted runner service는 systemd로 기동되고, Compose 서비스들은 `restart: unless-stopped` 정책으로 서버 재부팅 후 자동 복구됩니다.

확인할 화면:

| Tool | URL |
| --- | --- |
| Application | `http://YOUR_SERVER_IP:8080` |
| Grafana | `http://localhost:3000` through SSH tunnel |
| Prometheus | `http://localhost:9090` through SSH tunnel |
| Alertmanager | `http://localhost:9093` through SSH tunnel |

관측 도구는 기본적으로 서버의 `127.0.0.1`에만 bind됩니다. 로컬 PC에서 확인할 때는 다음처럼 SSH tunnel을 엽니다.

```bash
ssh -L 3000:localhost:3000 \
  -L 9090:localhost:9090 \
  -L 9093:localhost:9093 \
  -L 3100:localhost:3100 \
  ubuntu@YOUR_SERVER_IP
```

SSH 포트포워딩 서비스를 사용하는 환경에서는 서비스에서 제공한 SSH host와 port를 사용합니다.

## Portfolio Evidence

포트폴리오 README에 다음 캡처를 추가하면 좋습니다.

- Ansible playbook 실행 결과
- `docker compose ps` 결과
- restart policy 확인 결과
- Prometheus target UP 화면
- Grafana dashboard 화면
- Loki에서 `/api/error-test` 로그를 조회한 화면
- Alertmanager alert 화면

## Security Notes

실제 고객사 환경에서는 다음 조치가 필요합니다.

- Grafana 비밀번호 변경
- Prometheus, Grafana, Alertmanager, Loki 포트는 외부 공개 금지
- 서버 방화벽에서는 앱 포트와 SSH만 허용
- DB 포트 외부 노출 금지
- 운영 비밀번호는 Ansible Vault 또는 Secret Manager로 분리
