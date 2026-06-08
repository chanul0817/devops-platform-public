# AWS Terraform Template

이 디렉터리는 포트폴리오 마지막 확장 단계에서 사용할 AWS 예시 템플릿입니다.

현재 프로젝트의 기본 배포 방식은 `infra/onprem/`의 온프레미스 서버 배포입니다. AWS 리소스는 비용이 발생할 수 있으므로 바로 실행하지 않고, 온프렘 배포와 운영 문서가 완성된 뒤 선택적으로 사용합니다.

## Example

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

실습 후에는 비용 방지를 위해 반드시 정리합니다.

```bash
terraform destroy
```
