# 뉴스 알리미 디자인 리뷰 v2 — ChatGPT 답변 전문 (2026-11-15)

실제 화면 스크린샷 5장(홈/매칭 뉴스/설정/기사 상세/키워드 추가)을 보내 받아온 개선안.
기존 시안(Modern News Monitor, Primary #246BCE, Noto Sans KR) 유지하면서 수치만 다듬는 방향.

## 공통 디자인 시스템

| 항목 | 값 |
|---|---|
| Primary | #246BCE 유지 |
| Background | #F5F7FA |
| Surface | #FFFFFF |
| 기본 글자 | #172B4D |
| 보조 글자 | #667085 |
| 카드 테두리 | #E4E9F0 |
| 기본 좌우 여백 | 20dp |
| 카드 모서리 | 18dp |
| 버튼 모서리 | 16dp |
| 카드 사이 간격 | 16dp |
| 폰트 | Noto Sans KR 유지 |

## 홈 (우선순위 1)

- 파란 요약 카드 잘림: 고정 높이 대신 minHeight 148dp, 패딩 좌우 24/상하 20, 모서리 20dp.
  요약 제목 17sp Medium 흰색 / 매칭 건수 36sp Bold, height 1.2 / 모니터링 문구 13sp #DCEAFF.
  오른쪽 신문 아이콘 52dp #B8D5FF.
- 키워드 카드 84dp, 모서리 18dp, 내부 좌우 패딩 20dp. 키워드명 17sp Bold / 매칭 건수 15sp Medium / 삭제·이동 아이콘 22dp.
- '2분 전 확인'은 요약 카드 바로 아래 오른쪽 정렬, 12sp #8993A2.
- 하단 내비게이션: 아이콘 아래에 홈/뉴스/설정 글자 추가. 높이 72dp, 흰색.
- 앱바 높이 64dp 흰색, 앱 제목 23sp Bold. 화면 좌우 여백 20dp. 카드 아래 여백 20dp.
- 지금 확인 버튼 56dp, FAB 56dp.

## 매칭 뉴스 목록 (우선순위 3)

- '새 뉴스' 표시를 제목 옆에서 빼서 카드 오른쪽 상단 작은 배지로(12sp SemiBold) 또는 제목 아래 별도 행으로.
- 키워드 표시를 전체 너비 바에서 작은 캡슐 태그로: 배경 #E8F1FF / 글자 #246BCE / 높이 30dp / 좌우 패딩 12dp / Radius 15dp / 글자 14sp Medium.
- 뉴스 제목 17sp SemiBold, 줄 간격 1.4. 상단 제목 23sp Bold. 카드 패딩 20dp, 모서리 18dp, 테두리 #E4E9F0, 카드 사이 간격 16dp. 출처·시간 13sp Regular.
- 같은 뉴스가 여러 키워드에 매칭되면 태그 여러 개 표시, 기사는 한 번만 노출.
- '화면을 저장했어요' 토스트는 시스템 메시지라 앱 디자인과 무관.

## 설정 (우선순위 4)

- 그룹 제목 15sp SemiBold #667085, 카드 위 여백 20dp. 그룹 간격 24dp.
- 설정 행 높이 76dp 통일, 카드 내부 좌우 패딩 20dp, 구분선 1dp #E4E9F0.
- 설정 이름 16sp Medium / 보조 설명 13sp Regular. 카드 모서리 18dp, 카드 패딩 20dp.
- 화면 제목 23sp Bold. 토글은 Material 3 기본.
- 추가 권장: 알림 권한 꺼져 있으면 다시 허용하도록 안내, 15분 주기는 Android 백그라운드 환경에 따라 지연될 수 있다는 안내.

## 기사 상세 (우선순위 5)

- 제목 25sp Bold, 줄 간격 1.35, 제목 아래 여백 20dp.
- 출처 15sp SemiBold 파란색 / 시간 14sp Regular 회색, 사이 간격.
- 본문 17sp Regular, 줄 간격 1.7, 문단 간격 18dp, 색상 #344054.
- 원문 보기 버튼 56dp, 모서리 16dp, 위 간격 넉넉히. 본문 좌우 여백 20dp.
- 앱바 60dp, 뒤로 가기·공유 아이콘 24dp.
- 본문은 RSS 요약이므로 'RSS 요약 내용입니다. 전문은 원문에서 확인하세요.' 안내 유지.

## 키워드 추가 (우선순위 2)

- 전체를 SingleChildScrollView + SafeArea로 감싸 하단 안내 잘림 해결. 키보드가 올라와도 잘리지 않게 resizeToAvoidBottomInset: true.
- 안내 문구 16sp Regular #667085, 아래 여백 24dp. 입력창 높이 64dp, 모서리 16dp, 글자 16sp, 내부 패딩 좌우 20/상하 20, 테두리 #E4E9F0, 흰색 채움.
- 버튼 높이 56dp, 모서리 16dp, 입력창과 버튼 사이 20dp. 하단 안내 12sp #8993A2, height 1.5, 버튼 아래 여백 24dp.
- 좌우 여백 20dp, 상단 패딩 28, 하단 패딩 24.
- SingleChildScrollView 안에 Expanded를 넣으면 레이아웃 오류 — 주의.

## 공통 Flutter 테마 코드 (참고)

- ThemeData(useMaterial3: true), scaffoldBackgroundColor #F5F7FA.
- colorScheme fromSeed(seedColor #246BCE, surface #FFFFFF).
- appBarTheme: 배경 흰색, 글자 #172B4D, elevation 0, centerTitle false, title 23sp Bold.
- cardTheme: 흰색, elevation 0, radius 18, 테두리 #E4E9F0, margin zero.
  (참고: CardThemeData는 최신 Flutter API 기준. Flutter 3.32에서는 CardTheme 사용 여부 확인 필요.)
- elevatedButtonTheme: 배경 #246BCE, 글자 흰색, 최소 높이 56, elevation 1, radius 16, 글자 16sp w600.
- dividerTheme: 색상 #E4E9F0, 두께 1, 간격 1.

## 앱 아이콘

- 파란색 #246BCE 배경에 흰색 신문 + 알림 벨 플랫 디자인. 신문 내부 강조 #7EB2FF, 벨 외곽 강조 #C9DEFF.
- 스타일 Flat/Minimal, 1:1, 권장 원본 1024×1024px.
- Android Adaptive Icon 권장: 배경 레이어 #246BCE / 전경 레이어 신문+벨 / 전경은 중앙 안전 영역 안에.
- 아이콘 이미지 파일: ChatGPT 생성, 다운로드 완료 (1.1MB PNG).

## 최종 수정 우선순위

1. 홈 — 파란 카드 글자 잘림 수정
2. 키워드 추가 — 하단 안내 잘림 수정
3. 뉴스 목록 — 제목과 새 뉴스 배지 정렬
4. 설정 — 설정 행 높이와 글자 위계 통일
5. 기사 상세 — 본문 크기와 줄 간격 조정
6. 전체 — 카드 모서리, 패딩, 버튼 통일
7. 앱 아이콘 — Adaptive Icon 적용

## 디자인 방향 — Modern News Monitor 2.0

파란색 #246BCE·네이비 #172B4D·Noto Sans KR 유지. 카드 Radius 18dp, 좌우 여백 20dp, 버튼 높이 56dp 통일. Light/Dark 지원. 광고·사진·장식보다 뉴스 제목·매칭 키워드·시간·알림 상태가 명확히 보이는 것이 우선.
