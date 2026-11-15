# 뉴스 알리미 — 디자인 시안 (ChatGPT 작성, 전문)

- 출처: ChatGPT 대화 https://chatgpt.com/c/6af9192c-dd7c-83ec-b497-c799b7a1bd02
- 수신일: 2026-11-15
- 아래는 시안 전문이다. 말미의 '적용 메모'는 시안 자체가 아니라 v1에 적용하면서 정한 사항이다.

---

컨셉: Modern News Monitor — 신뢰감 있는 뉴스 서비스 + 간결한 키워드 모니터링. Flutter Material 3 기반, 라이트/다크 모드 모두 지원.

## 1. 컬러 팔레트

- Primary: 라이트 #246BCE / 다크 #6BA8FF
- Background: 라이트 #F5F7FA / 다크 #121923
- Surface(카드): 라이트 #FFFFFF / 다크 #1C2735
- 카드 테두리: 라이트 #E4E9F0 / 다크 #344154
- 기본 글자: 라이트 #172B4D / 다크 #F1F5F9
- 보조 글자: 라이트 #667085 / 다크 #9BA9BC
- 키워드 강조 표시: 라이트 #FFF0B3 / 다크 #66521F
- 성공/새 뉴스: 라이트 #16845B / 다크 #55C99A
- 오류: 라이트 #D64545 / 다크 #FF7777
- 입력창(다크): #202D3D, 버튼 글자(다크): #10233D

## 2. 폰트 및 규격

한글 폰트 Pretendard. 앱 제목 22sp Bold, 화면 제목 20sp Bold, 카드 제목 16sp SemiBold, 본문 14sp Regular, 보조 설명 12sp Regular, 버튼 15sp SemiBold. 기본 좌우 여백 20dp, 카드 모서리 14dp, 버튼 높이 52dp, 입력창 높이 54dp, 하단 내비게이션 64~80dp, 최소 터치 영역 48x48dp. ThemeMode.system 사용.

## 3. 화면 ① 홈 (키워드 목록)

상단 앱바(뉴스 알리미 로고 + 알림 아이콘, 높이 60dp), 오늘의 뉴스 요약 카드(높이 112dp, Primary 배경 흰색 글씨, 오늘의 매칭 수 32sp Bold), 키워드 목록(키워드 카드 높이 76dp, radius 14dp, 키워드 16sp + 매칭 건수 14sp Primary 색), 하단 내비게이션 홈/뉴스/설정(72dp), 키워드 추가는 우측 하단 원형 플로팅 버튼 56dp Primary 색. 키워드 카드 누르면 해당 키워드 뉴스 목록으로 이동. 오른쪽 상단에 마지막 RSS 확인 시간 표시. 키워드 없으면 빈 화면에 추가 유도.

## 4. 화면 ② 키워드 추가

뒤로가기 + 제목 '키워드 추가', 안내 문구 '관심 있는 뉴스 키워드를 등록해 보세요.'(14sp 보조 글자), 키워드 입력창(높이 56dp, 테두리 #D5DCE5), 등록 버튼(높이 52dp, Primary, 흰색 15sp SemiBold), 하단 안내 '연합뉴스 RSS에서 해당 키워드가 포함된 뉴스를 확인합니다.'(12sp). Enter 키로도 등록, 중복 등록 방지, 공백만 입력 시 등록 차단, 등록 완료 시 홈으로 이동 + 성공 메시지.

## 5. 화면 ③ 매칭 뉴스 목록

상단에 선택된 키워드 표시, 아래 매칭 뉴스를 최신순으로. 뉴스 카드 100~130dp: 기사 제목 16sp, 매칭 키워드는 제목 안에서 노란 배경(#FFF0B3)으로 강조, 출처·시간 12sp(#8993A2), 새 뉴스 표시 10~12sp(#16845B), 구분선 1dp #E4E9F0. 카드 누르면 기사 상세로 이동. 같은 기사가 여러 키워드에 매칭되면 중복 노출 방지하고 해당 키워드들 함께 표시. 새로 들어온 뉴스는 읽지 않음 표시. 뉴스 없으면 안내 문구.

## 6. 화면 ④ 기사 상세

상단 앱바 뒤로가기/공유하기(56dp), 출처 13sp Primary 색, 기사 시간 12sp, 기사 제목 23sp Bold, 키워드 태그 높이 28dp 연한 파란색, 기사 본문 16sp 줄 간격 1.7(본문은 RSS 요약 내용 표시 — RSS에 전문이 없으면 요약 + 원문 보기), 원문 보기 버튼 높이 52dp Primary. 제목·본문은 텍스트 선택/복사 가능하게. 원문 보기는 외부 브라우저로 연결.

## 7. 화면 ⑤ 설정

알림 설정 그룹(전체 알림 ON/OFF, 알림 확인 주기, 새 뉴스만 알림, 알림 테스트) + 앱 설정 그룹(테마: 시스템/라이트/다크, RSS 출처: 연합뉴스, 앱 버전). 설정 그룹 제목 14sp 보조 글자, 설정 항목 높이 60dp, 토글 스위치 Material Switch Primary 색, 구분선 1dp.

## 8. 화면 이동 구조

홈 → 키워드 추가 / 뉴스 목록 → 기사 상세 / 설정. 하단 내비게이션 홈(house)/뉴스(newspaper)/설정(settings).

## 9. 권장 프로젝트 구조

lib/theme/(app_theme, light_theme, dark_theme), lib/screens/(home, add_keyword, news_list, news_detail, settings), lib/models/(keyword, news), lib/services/(rss, keyword, notification), lib/widgets/(keyword_card, news_card, bottom_navigation), lib/providers/(keyword, settings). 패키지: http, xml, shared_preferences, sqflite 또는 drift, flutter_local_notifications, workmanager, provider, url_launcher, Pretendard 폰트(로컬 등록 또는 google_fonts).

---

## 적용 메모 (v1 적용 시 정한 사항 — 시안 본문이 아님)

- **알림 주기**: 15/30/60분만 유지한다. 시안에 5분·10분도 나와 있지만 안드로이드 WorkManager 최소 간격이 15분이라 5분 단위 실행은 보장되지 않는다.
- **서버 + FCM 푸시**: v1 범위 밖이다. 시안에서 서버 연동을 추천했지만 사용자는 폰 안에서 돌리는 로컬 앱을 원했으니, 로컬 WorkManager + 로컬 알림으로 그대로 가고 README에 향후 과제로만 적는다.
- **기사 상세 본문**: RSS description 요약까지만 보여주고, 전문은 원문 보기 버튼으로 외부 브라우저 연결한다.
- **테마 위치**: `lib/theme.dart` 한 곳에 모아두기로 한 방침을 유지한다. 색상 hex를 위젯에 하드코딩하지 않는다. (시안의 `lib/theme/` 폴더 구조 대신 단일 파일로 적용했다.)
- **폰트**: 시안은 Pretendard를 지정했지만, Pretendard는 Google Fonts에 없어 `google_fonts` 패키지로 불러올 수 없다(2026-11-15 확인: Google Fonts css2 API에서 Pretendard 400 반환, Noto Sans KR은 200). v1에서는 Google Fonts의 Noto Sans KR을 적용했다. Pretendard TTF를 로컬에 등록하면 `lib/theme.dart`의 폰트 호출만 바꾸면 된다.
- **저장소**: 시안은 sqflite 또는 drift를 권장했지만, v1 데이터(키워드·매칭 기사 최대 100건·설정)는 SharedPreferences로 충분해 `shared_preferences`만 쓴다. 규모가 커지면 sqflite/drift로 옮긴다.
- **상태 관리**: 시안은 provider 패키지를 권장했지만, v1 설정 상태는 `ChangeNotifier` + `AnimatedBuilder`로 직접 연결했다. 별도 provider 패키지를 쓰지 않았다.
- **입력창 높이**: 시안 2번 항목에는 54dp, 4번 화면에는 56dp로 적혀 있어 56dp로 통일했다.
