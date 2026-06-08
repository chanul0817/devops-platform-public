# On-premise Deployment

이 디렉터리는 클라우드 비용 없이 고객사 내부 Linux 서버 또는 개인 VM에 DevOps 운영 환경을 배포하기 위한 Ansible 구성입니다.

## Target

- Ubuntu 22.04/24.04 또는 Debian 계열 Linux 서버
- SSH 접속 가능
- 최소 2 vCPU, 4GB RAM 권장
- 외부 접근 포트: 8080, SSH
- Docker image pull, Gradle dependency download, GitHub Actions runner outbound 연결이 가능하도록 인터넷 접근 필요

## Files

| File | Purpose |
| --- | --- |
| `inventory.example.ini` | 대상 서버 예시 |
| `playbook.yml` | Docker 설치, deploy user 권한 구성, 프로젝트 복사, Compose 실행 |

## Usage

수동으로 대상 서버에 Docker를 설치해야 한다면 Docker 공식 APT 저장소를 사용합니다.

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

sudo 비밀번호가 필요한 서버라면 다음처럼 실행합니다.

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

## Verify

```bash
curl http://YOUR_SERVER_IP:8080/api/health
```

서버 내부에서 전체 smoke test를 실행할 수 있습니다.

```bash
cd /opt/devops-consulting-springboot
./ops/smoke-test.sh
```

브라우저에서 확인할 주소:

| Service | URL |
| --- | --- |
| Application | `http://YOUR_SERVER_IP:8080` |
| Grafana | `http://localhost:3000` through SSH tunnel |
| Prometheus | `http://localhost:9090` through SSH tunnel |
| Alertmanager | `http://localhost:9093` through SSH tunnel |

관측 도구는 기본적으로 서버의 `127.0.0.1`에만 bind됩니다. 필요 시 SSH tunnel이나 VPN으로 접근합니다.

## Notes

실제 고객사 환경에서는 Grafana, Prometheus, Alertmanager, Loki 포트를 VPN 또는 사내망에서만 접근 가능하게 제한하는 것이 좋습니다.

초기 Ansible 배포 후에는 온프렘 서버 또는 같은 내부망에 GitHub Actions self-hosted runner를 설치하고 `onprem` 라벨을 부여합니다. 이후 CD는 외부 GitHub-hosted runner가 SSH로 들어오는 방식이 아니라, 내부 runner가 배포 패키지 파일을 동기화하고 `.env`의 `APP_IMAGE`를 갱신한 뒤 `docker compose up -d --no-build --remove-orphans`를 실행하는 방식으로 동작합니다.
