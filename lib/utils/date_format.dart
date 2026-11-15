/// 기사 시간·마지막 확인 시간 표시용 포맷터.
String formatArticleTime(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diffDays = today.difference(day).inDays;
  final hhmm =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (diffDays == 0) return '오늘 $hhmm';
  if (diffDays == 1) return '어제 $hhmm';
  return '${local.month}월 ${local.day}일 $hhmm';
}

/// 홈 화면 오른쪽 상단에 표시하는 마지막 RSS 확인 시간.
String formatLastCheck(DateTime? dt) {
  if (dt == null) return '아직 확인하지 않았습니다';
  final local = dt.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return '방금 확인';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전 확인';
  return '마지막 확인: ${formatArticleTime(local)}';
}
