"""live_seed.json(앱 저장 내용) -> 웹 빌드 localStorage 시드(seed_ls.json).

사용법: python3 seed_to_localstorage.py /tmp/live_seed.json <웹사본>/seed_ls.json

컨테이너는 UTC라 저장된 시각(시간대 없는 현지 시각)을 한국 시각(+9시간)으로 옮긴다.
브라우저는 Asia/Seoul 로 띄운다 (shot.js). 마지막 확인 시각은 '지금'으로 둬서
웹에서 자동 확인(CORS로 실패)이 돌지 않게 한다.
"""
import datetime
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
d = json.load(open(src))


def kst(s):
    t = datetime.datetime.fromisoformat(s) + datetime.timedelta(hours=9)
    return t.isoformat(timespec='milliseconds')


def conv(lst):
    out = []
    for x in lst or []:
        a = json.loads(x)
        a['pubDate'] = kst(a['pubDate'])
        a['fetchedAt'] = kst(a['fetchedAt'])
        out.append(json.dumps(a, ensure_ascii=False))
    return out


now = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=9)).replace(tzinfo=None)
now = now.isoformat(timespec='milliseconds')
ls = {
    'flutter.keywords': json.dumps(d['keywords'], ensure_ascii=False),
    'flutter.matched_articles': json.dumps(conv(d.get('matched_articles')), ensure_ascii=False),
    'flutter.latest_articles': json.dumps(conv(d.get('latest_articles')), ensure_ascii=False),
    'flutter.last_check_at': json.dumps(now),
    'flutter.last_fetch_failed': 'false',
    'flutter.bg_last_run_at': json.dumps(now),
    'flutter.bg_last_result': json.dumps('새 뉴스 3건', ensure_ascii=False),
    'flutter.battery_prompt_shown': 'true',
}
json.dump(ls, open(dst, 'w'), ensure_ascii=False)
print('ok', dst)
