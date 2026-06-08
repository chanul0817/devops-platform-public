# 10. AWS Future Extension

## Purpose

AWS 배포는 비용이 발생할 수 있으므로 1차 포트폴리오에서는 선택 확장으로 둡니다. 온프레미스 단일 서버 배포가 완료된 뒤, 마지막 단계에서 AWS EC2/RDS/ECR/EKS 등으로 확장할 수 있습니다.

## Current Scope

현재 `infra/terraform/`은 다음 리소스의 예시 템플릿만 제공합니다.

- VPC
- Public Subnet
- Internet Gateway
- Route Table
- Security Group
- EC2
- Key Pair

## When to Add AWS

다음 자료가 준비된 뒤 추가하는 것을 권장합니다.

- 온프렘 배포 성공 화면
- Grafana/Prometheus/Loki/Alertmanager 캡처
- Runbook 문서
- 장애 테스트 기록

## Extension Plan

| Step | Goal |
| --- | --- |
| 1 | Terraform으로 EC2 생성 |
| 2 | Ansible로 EC2에 동일한 Docker Compose 스택 배포 |
| 3 | PostgreSQL을 RDS로 분리 |
| 4 | Docker image를 GHCR 또는 ECR로 관리 |
| 5 | HTTPS와 도메인 적용 |
| 6 | EKS와 Argo CD 기반 GitOps로 확장 |

## Cost Control

- 실습 후 EC2와 Elastic IP를 삭제한다.
- RDS는 마지막 단계에서만 사용한다.
- EKS는 비용이 커질 수 있으므로 포트폴리오 최종 확장으로만 고려한다.
- Terraform state와 destroy 절차를 README에 명확히 적는다.
