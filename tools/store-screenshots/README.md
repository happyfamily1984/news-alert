# 스토어 스크린샷 만들기

앱을 웹으로 빌드해 폰 크기(360×640, 배율 3 → 1080×1920)로 실제 화면을 찍고,
문구·프레임을 입혀 `play-release/graphics/`에 저장한다. 데이터는 실제 최신 기사다.
(안드로이드 에뮬레이터를 못 쓰는 클라우드 환경용 방법. 화면은 플러터 코드 그대로라 앱과 같다.)

## 순서

1. **실제 기사 수집** (첫 실행 상태 재현)
   ```
   cp tools/store-screenshots/live_seed_test.dart.txt test/zz_live_seed_tmp_test.dart
   flutter test test/zz_live_seed_tmp_test.dart && rm test/zz_live_seed_tmp_test.dart
   ```
2. **웹 사본 빌드** (저장소에는 web/ 폴더를 넣지 않는다)
   ```
   W=<임시폴더>/web
   mkdir -p $W && cp -r lib assets pubspec.yaml pubspec.lock analysis_options.yaml $W/
   (cd $W && flutter create --platforms web --project-name news_alarm . && flutter build web --release)
   python3 tools/store-screenshots/seed_to_localstorage.py /tmp/live_seed.json $W/seed_ls.json
   cp tools/store-screenshots/*.js tools/store-screenshots/*.html $W/
   (cd $W/build/web && python3 -m http.server 8765 &)
   ```
3. **촬영** (Playwright, 한 장씩 찍어야 한글 글꼴이 깨지지 않는다)
   ```
   cd $W && export NODE_PATH=$(npm root -g)
   node shot.js $W $W/n_home.png '[{"wait":6000}]'
   node shot.js $W $W/n_news.png '[{"click":[180,603]}]'                      # 매칭 뉴스 탭
   node shot.js $W $W/n_latest.png '[{"click":[180,603]},{"click":[270,92]}]'  # 최신 뉴스
   VH=2600 node shot.js $W $W/n_settings_tall.png '[{"click":[300,2563],"wait":3000}]'
   # n_contact.png = n_settings_tall.png 의 '앱 설정~문의' 부분을 1080×1920으로 자른 것
   ```
   클릭 좌표는 CSS 픽셀(360 폭 기준). 하단 탭: 홈(60,603) 매칭 뉴스(180,603) 설정(300,603).
4. **문구·프레임 합성**
   ```
   cp $W/n_*.png $W/build/web/ && cp $W/n_home.png $W/build/web/s_home.png
   cp play-release/graphics/icon-512.png $W/build/web/icon.png
   cp $W/frame.html $W/feature.html $W/build/web/
   node render.js <저장소>/play-release/graphics
   ```
   문구는 `render.js`의 `shots` 배열에서 바꾼다.
