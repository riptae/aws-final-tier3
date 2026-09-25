# MySQL To-do 최소 서비스

## 구조와 실행 순서

- `todo-api/`: Spring Boot 3.5, JDBC, MySQL, Flyway. Java 17로 빌드하며 Java 21에서도 실행한다.
- `web/`: Nginx에 배포할 정적 HTML, JS, CSS. `/api/`를 통해 App에 요청한다.
- `todo-api/src/main/resources/db/migration/`: 빈 DB에 최초 테이블을 생성한다. 재시작 시 데이터를 삭제하지 않는다.

DB 준비 → JAR 빌드 → Bastion 산출물 업로드 → 04 App 배포 → 05 Web 배포.
현재 Terraform에는 DB가 없으므로 MySQL 8 또는 RDS를 별도로 준비해야 한다.
DB 이름은 `appdb`로 만들고, App SG에서 DB 3306으로 접근 가능해야 한다.
앱 DB 계정에는 테이블 생성(초기 마이그레이션) 및 조회/추가/수정/삭제 권한이 필요하다.
두 App은 동일 DB를 사용한다. Flyway가 마이그레이션 이력을 관리한다.

## API

| 메서드 | 경로 | 동작 |
|---|---|---|
| GET | /api/health | DB 연결 확인, 정상 시 200 |
| POST | /api/todos | 생성, 201 |
| GET | /api/todos | 최신순 목록, 200 |
| PUT | /api/todos/{id} | 제목 및 완료 상태 수정, 200 |
| DELETE | /api/todos/{id} | 삭제, 204 |

POST: `{"title":"첫 번째 할 일"}`
PUT: `{"title":"수정한 할 일","completed":true}`
제목은 공백만으로 구성할 수 없으며 최대 200자다. 없는 ID의 수정/삭제는 404다.
SQL은 파라미터 바인딩을 사용하며 화면은 사용자 입력을 HTML로 해석하지 않는다.
인증 기능 없는 학습용 최소 앱이다. 아직 공개 서비스용 사용자별 권한 분리는 없다.

## Windows 빌드

```powershell
cd C:\terraform\aws-final-tier3\modules\compute\services\todo-api
.\mvnw.cmd clean package
```

결과는 `target/app.jar`. 테스트는 H2의 MySQL 모드를 사용하므로 DB 없이 실행된다.
이는 실제 MySQL/RDS 통합 검증을 대체하지 않는다.

## 로컬 MySQL 실행 예시

DB와 계정을 만든 후 PowerShell에서 환경변수를 지정한다.

```powershell
$env:DB_URL = 'jdbc:mysql://localhost:3306/appdb?connectionTimeZone=UTC'
$env:DB_USERNAME = 'YOUR_DB_USER'
$env:DB_PASSWORD = 'YOUR_DB_PASSWORD'
java -jar target/app.jar
```

실제 비밀번호를 소스 파일에 넣지 않는다. DB에 접속하지 못하면 앱 시작 또는 health 검사가 실패한다.

## 기존 Ansible로 배포

내 PC에서 `target/app.jar`를 Bastion의 `/home/ec2-user/deploy/artifacts/app.jar`로 복사한다.
`app.env.example`을 참고해 Bastion의 `artifacts/app.env`에 실제 DB 정보를 입력하고 권한을 600으로 지정한다.
이 파일은 systemd EnvironmentFile 형식이다. `export`를 붙이지 않는다.
예제의 `sslMode=REQUIRED`는 연결 암호화를 요구한다. 서버 인증서 검증이 필요한 환경은 CA와 VERIFY_IDENTITY를 추가 구성한다.

`web/`의 세 파일은 Bastion의 `artifacts/web/`에 복사한다.

```bash
cd /home/ec2-user/deploy
source /opt/ansible/bin/activate
chmod 600 artifacts/app.env
ansible-playbook -i inventory.yml playbooks/04-deploy-app.yml --ask-pass
ansible-playbook -i inventory.yml playbooks/05-deploy-web.yml --ask-pass
```

App 실행 로그: `sudo journalctl -u tier3-app -n 100 --no-pager`
Web→App 8080 및 App→DB 3306의 네트워크 연결을 확인한다.
Private Web은 Bastion SSH 터널을 통해 브라우저에서 확인할 수 있다.
App 재시작 후 목록이 유지되는지 실제 DB에서 검증한다.

JAR, app.env 및 Web 파일은 user data에 자동 포함되지 않는다.
