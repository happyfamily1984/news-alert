# play-release — 뉴스 알리미 1.1.0 (버전 코드 17)

| 파일 | 용도 |
|---|---|
| `news-alarm-1.1.0+17.aab` | 플레이 콘솔 업로드용. 업로드 키(CN=News Alarm Upload)로 서명. **저장소에는 없음** (용량) |
| `news-alarm-1.1.0+17-test.apk` | 폰에 직접 설치해 확인하는 테스트용. 공개 테스트 키 서명. **저장소에는 없음** |
| `graphics/` | 앱 아이콘 512, 그래픽 이미지 1024×500, 휴대전화 스크린샷 4장 (2026-11-26 실제 기사로 촬영) |
| `listing.md` | 스토어 등록정보 문구 (앱 이름·설명·연락처) |
| `release-notes.md` | 출시 노트, 심사 거부에 대한 회신 문구, 변경 내역 |
| `release-guide.md` | 플레이 콘솔 입력 가이드 (앱 콘텐츠·데이터 보안·뉴스 앱 선언) |

- 업로드 키 인증서 SHA-256: `72:4B:27:E2:FB:FF:18:A3:37:64:7A:DC:A8:7C:06:39:94:E4:7E:32:40:16:54:19:FA:FE:03:80:BE:F9:5D:FA`
- 대상 SDK 36, 최소 SDK 26
- AAB·APK는 `flutter build appbundle` / `flutter build apk`로 다시 만든다 (`release-guide.md` 3번 참고).
