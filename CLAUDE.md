# 뉴스 알리미 (news-alert) — 프로젝트 인계 메모

키워드를 등록하면 국내 언론사 RSS에서 해당 키워드 기사가 올라올 때 알림을 주는 Flutter 안드로이드 앱.
패키지명 `com.happyfamily.newsalarm` (플레이스토어 등록, 바꿀 수 없음). 사용자 답변은 항상 한국어.

## 현재 상태 (2026-11-27)

- 최신 버전 **1.1.0 (버전 코드 17)**, main = 출시 코드. 다음 업로드는 버전 코드 **18 이상**.
- 플레이스토어: **조직 계정**(비공개 테스트 12명·14일 조건 없음, 바로 프로덕션).
  - 1.0.0(16) 심사에서 "뉴스 및 잡지 정책 위반"으로 거부됨
    (첫 실행 화면이 비어 '뉴스 섹션 미작동', 출처·연락처 요건).
  - 1.1.0(17)으로 대응. 대응 내용과 심사 회신 문구는 `play-release/release-notes.md`.
- 개발자 연락처: 이메일 happyfamily1984.3@gmail.com,
  웹사이트 https://happyfamily1984.github.io/jihan-distribution/ (앱 설정 > 문의, 처리방침, 등록정보에 표시)
- 개인정보처리방침 URL: https://github.com/happyfamily1984/news-alert/blob/main/docs/privacy-policy.md
  (main 기준이라 문서를 바꾸면 main에 반영돼야 보인다)

## 사용자 공통 규칙 (모든 앱)

- 뒤로가기: 이전 행동(선택 모드·수정·열린 창 취소) 또는 이전 화면으로.
  뉴스·설정 탭 → 홈 탭, 홈에서 뒤로가기 → "앱을 종료하겠습니까?" → 예면 종료.
  (`lib/screens/main_screen.dart`, 매니페스트 `enableOnBackInvokedCallback="false"`로 유지)

## 구조

- `lib/services/rss_service.dart` — 피드 목록(`RssService.feeds`, 출처 목록 `RssService.sources`)과 파서.
  - 연합뉴스 10개 피드, 조선일보 1개, 동아일보 5개(직접 RSS),
    중앙일보·YTN·MBC·KBS는 구글 뉴스 RSS(`site:` + `when:1d`, 제목 꼬리말 제거, 요약 없음).
  - 응답은 UTF-8로 직접 디코딩(동아는 헤더에 문자셋이 없음).
- `lib/utils/rss_date.dart` — 발행일 파서. `+0900`/`+0000`/`GMT`/ISO 지원.
  (예전 `HttpDate.parse`는 GMT만 읽어 연합·조선 발행일이 '가져온 시각'으로 잘못 나왔다)
- `lib/utils/keyword_match.dart` — 한글은 포함 비교, 영문·숫자 키워드는 단어 경계 비교('AI'≠'KORAIL').
- `lib/services/news_check_service.dart` — 수집→최신 뉴스 저장(언론사별 최대 10건)→키워드 매칭→저장→알림.
  `CheckResult.allFailed`면 기존 목록을 건드리지 않는다. 수동 확인과 백그라운드가 같은 로직.
- `lib/services/storage_service.dart` — SharedPreferences. 매번 `reload()`(백그라운드 isolate와 동기화).
  첫 실행이면 추천 키워드 `경제·부동산·AI` 등록(사용자가 다 지우면 다시 안 넣음). 기사는 30일 보관.
- `lib/background_task.dart` — WorkManager 주기 작업(15/30/60분, 정책 update). 실행 기록을 설정에 표시.
- 화면: 홈(요약·키워드·최신 뉴스 5건) / 매칭 뉴스(키워드 뉴스·최신 뉴스 전환) / 설정(자동 확인·출처·문의).
- 배터리: 플레이 정책상 `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`를 쓰지 않고 앱 정보 화면을 연다
  (`MainActivity.kt` 채널 `com.happyfamily.newsalarm/battery`). `FOREGROUND_SERVICE`는 매니페스트에서 제거.

## 빌드·테스트

- Flutter **3.32.0** 고정(CI와 같게), compileSdk·targetSdk **36**, minSdk 26, AGP 8.9.1, Gradle 8.11.1, NDK 27.0.12077973.
- `flutter analyze --no-fatal-infos`, `flutter test` (25건). CI(`.github/workflows/build-apk.yml`)도 같은 순서.
- 클라우드 컨테이너에서 처음부터 빌드하려면:
  ```
  # Flutter
  curl -fsSL -o f.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz
  tar xf f.tar.xz -C /opt/fl && git config --global --add safe.directory /opt/fl/flutter
  # Android SDK (cmdline-tools 압축을 /opt/android-sdk/cmdline-tools/latest 에 풀고)
  sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973"
  # gradle-wrapper.jar 는 저장소에 없음 (CI처럼 받아 온다)
  curl -fsSL -o android/gradle/wrapper/gradle-wrapper.jar https://raw.githubusercontent.com/gradle/gradle/v8.9.0/gradle/wrapper/gradle-wrapper.jar
  ```
- 안드로이드 에뮬레이터는 클라우드에서 못 띄운다(KVM 없음). 화면 확인은 웹 빌드로 한다 → `tools/store-screenshots/README.md`.

## 서명 (중요)

- **직접 설치용 APK**: 저장소의 공개 테스트 키 `android/app/app-keystore.p12` (비번 android). 플레이에 쓰지 않는다.
- **플레이 업로드 키**: 저장소에 **없다**. 사용자가 보관 중인 `news-alarm-upload-key.zip`
  (upload-keystore.p12 + key.properties + base64). 별칭 `upload`.
  인증서 SHA-256 `72:4B:27:E2:FB:FF:18:A3:37:64:7A:DC:A8:7C:06:39:94:E4:7E:32:40:16:54:19:FA:FE:03:80:BE:F9:5D:FA`
  - 환경변수 `NEWSALARM_UPLOAD_KEYSTORE`(경로)·`_STORE_PASSWORD`·`_KEY_ALIAS`·`_KEY_PASSWORD`가 있으면
    `flutter build appbundle`이 업로드 키로 서명한다(`android/app/build.gradle.kts`).
  - 깃허브 시크릿 `UPLOAD_KEYSTORE_BASE64`·`UPLOAD_STORE_PASSWORD`·`UPLOAD_KEY_ALIAS`·`UPLOAD_KEY_PASSWORD`를
    등록하면 CI가 플레이용 AAB(`news-alarm-play-aab`)도 만든다. 키 파일 없이도 출시 가능해진다.
  - 키를 잃으면 플레이 콘솔에서 '업로드 키 재설정'을 요청(새 키 생성 → 인증서 제출 → 며칠 소요).
  - 사용자가 별도로 만든 업로드 키도 있다고 했다. 플레이에 처음 등록된 키가 어느 것인지는
    플레이 콘솔 > 앱 무결성 > 앱 서명의 '업로드 키 인증서' SHA-256과 위 값을 비교해서 확인한다.

## 출시 자료

- `play-release/` — 등록정보(`listing.md`), 콘솔 입력 가이드(`release-guide.md`), 출시 노트(`release-notes.md`),
  이미지(`graphics/`). AAB·APK는 용량 때문에 커밋하지 않는다(.gitignore).

## 알려진 문제·주의

- 동아일보 RSS는 2026-11-26부터 클라우드 컨테이너에서 접속이 안 된다(22일엔 됐음). 해외 IP 차단 추정.
  한국 휴대폰에서 되는지는 미확인. 실패 피드는 건너뛰므로 앱은 정상 동작.
- 구글 뉴스 RSS 약관은 '개인적·비상업적 용도'만 허용. 광고·유료화를 붙이면 중앙·YTN·MBC·KBS 출처 재검토.
- 백그라운드 알림은 폰 절전(특히 삼성)에 따라 늦을 수 있다. 설정 > 자동 확인 > '마지막 자동 확인'으로 진단.
