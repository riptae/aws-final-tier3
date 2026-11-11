### 목적
To do list 앱이 가동될 인프라를 AWS 3-TIER로 구성. Ansible로 배포하고 테스트하였다.
목적은 다음과 같다.

- 인프라 엔지니어로 하던 노드 설치, 네트워크 연결을 EC2와 VPC에서 한다.
- 폐쇄망만 다루던 제한된 경험을 ACM, Cloudfront, Route53, IAM, CloudWatch 등으로 확장시킨다.
- IAM 권한 + STS를 통해 Terraform이 AWS 리소스에 접근하도록 구성, 공식 문서를 참고해 변수를 참조·전달하며 리소스를 구성하는 IaC 방식에 익숙해진다.

<br>
<br>

### 아키텍쳐

- A : USER에서 ALB까지
- B : ALB에서 RDS까지 (3-tier)
- C : Cloudwatch -> Gmail Alarm

<img width="80%" alt="3-tier_simple" src="https://github.com/user-attachments/assets/ae140fc6-0ea5-40e1-9ad2-bb71569d3eb8" />
<br>
modules에 리소스를 작성<br>
main.tf에 최소 NW + WEB(nginx dummy page) 만 불러오고, apply하는 것으로 리소스를 더해나갔다.

<br>
<br>

### A : USER에서 ALB까지
https://going2alaska.tistory.com/619<br>
<img width="70%" alt="image" src="https://github.com/user-attachments/assets/ec59df4a-1859-4f3e-8deb-1eb0814ec415" />

*Route53 + Cafe24 도메인 + TLS(ACM) 조합에는 리소스 생성에 순서가 필요했다.

이슈 : ACM 인증서 issue pending.

TLS인증에 필요한 조합을 체크해나갔다.

- Cafe24도메인에 Hosted Zone생성시 만들어진 NameServer 4개 연결. 이후 반영되었는지.
- ACM이 생성한 CNAME이, Record로 만들어져 Zone에 있는지.

이후 인증서가 발급되고, Cloudfront에 HTTPS를 적용, A Record도 생성하여 User가 도메인으로 접속할 수 있게 하였다.
<img width="70%" alt="image" src="https://github.com/user-attachments/assets/5d06f50a-a48e-4b0f-8bed-c5ae21ed3f66" />

<br>
<br>

### B : 3-TIER + Ansible 배포
<img width="70%" alt="image" src="https://github.com/user-attachments/assets/dc76bd93-4726-4a1c-8ea5-b59d758930cc" />

배포를 어떻게 해야 효율적인지 고민했다.
 
24년 CICD 실습 때는 Git push시 Travis CI가 감지, 빌드, S3에 파일을 업로드하고, AWS CodeDeploy에게 배포를 요청하는 방식.
(https://going2alaska.tistory.com/399)

25년 AWS 첫 학습시,
- 로컬 WSL Ansible로 직접 인벤토리, 플레이북을 작성하여 배포. 
- Github Actions에 OIDC로 연결, Push시 Github Runners에 Ansible을 실행하게 해서 플레이북 자동 작성, 배포 등.
(https://going2alaska.tistory.com/613)

그러나 저건 서비스가 단일 노드 위에서 간단하게 작동하는 케이스고,<br>

지금은 WEB이 정적 화면을 제공하면서 /api/ 요청을 APP으로 전달해야 했고, APP은 RDS로 연결이 필요했다.
그 전에 nginx, springboot, mysql client를 설치하고, ssh 활성화 작업도 필요했는데, EC2노드 초기화시(user_data) 어디까지 해야할지도 고민했다.

결론은 bastion + ansible을 사용하되, Codex에게 스크립트를 짜달라고 요청. 아래와 같이 편하게 배포할 수 있었다.<br>

(https://going2alaska.tistory.com/651)

리소스 생성(노드 초기화 시)<br>
1. bastion에 ansible 설치.
2. web과 app의 Private IP룰 받아 inventory를 생성.
3. inventory와 미리 작성해둔 playbook을 Base64로 인코딩해 bastion의 user_data에 전달, bastion 초기화 시 /home/ec2-user 안에 파일로 복원.

배포 파일 준비<br>
4. Local에서 APP JAR를 빌드, WEB 정적 파일을 SFTP로 Bastion에 전달.<br>
5. DB접속정보를 app.env로 준비.

Playbook 실행.<br>
6. Bastion-> WEB/APP접속 및 초기화 확인 / WEB설정 / APP준비 /  APP배포 / WEB배포<br>

<br>
<br>

### C : CloudWatch -> SNS -> Alarm
<img width="70%" alt="image" src="https://github.com/user-attachments/assets/ba13d409-07e2-49d7-9fb9-3c24fb2082bd" />

ALB가 Web EC2 두 대의 / 경로를 HTTP로 헬스 체크하도록 구성. 특정 조건에서 SNS를 통해 Gmail로 알림을 보낸다.

현재는 모니터링 구축 실습을 위해 하나의 메트릭만 설정했는데, 실제 운영에서는 이것보다는 많아야 한다.

- WEB뿐 아니라 APP도 RDS도 있어야 한다.
- WEB 내에서도 더 세분화된 메트릭이 필요하다.<br>
  ㄴ health check가 실패하는 상황은, 실제로 Nginx가 중지, EC2 내부 문제, ALB에서 WEB까지 네트워크 문제. 모두를 포함하기 때문.

그런데 온프레에서 고객사로부터 '서버가 안돼요.' 라는 소리를 들으면, 관제 노드 에서 문제가 생겼는지, 전기가 나갔는지, 디스크 장애가 생겨서 OS가 깨졌는지, nginx서비스가 꺼졌는지, subnet이나 라우팅(스위치)에 문제가 있는지 등 여러 상황을 확인해가면서 어느 단에 문제가 생겼는지 구분할 수 있다.

이와 비슷하게 health check 실패라는 하나의 메트릭만 가지더라도,
- ALB Target Group에서 비정상 대상과 실패 사유 확인.
- EC2 대시보드에서 상태를 검사
- Bastion을 통해 WEB에 접속해 로컬로 nginx서비스 응답을 체크.

등 직접 원인을 특정할 수 있을 것이다.

결론은 엔지니어가 원인을 특정할 수 있도록 어느 정도 아키텍처 지식은 있다고 가정한 상태에서,

너무 많지도 적지도 않은 최적의 메트릭들을 어떤 세트로 대시보드와 알림에 제공할 지 실제 현장에서 설계해보고 싶다. 
