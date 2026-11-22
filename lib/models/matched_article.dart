/// 키워드와 매칭된 뉴스 기사 한 건.
///
/// [id]는 RSS guid(기사 고유 주소)이며 중복 제거 기준이다.
/// [keywords]는 이 기사와 매칭된 키워드 목록이다 (여러 키워드 매칭 가능).
/// [source]는 기사를 가져온 언론사 (RssService.sources 중 하나).
class MatchedArticle {
  final String id;
  final String title;
  final String link;
  final DateTime pubDate;
  final String description;
  final List<String> keywords;
  final DateTime fetchedAt;
  final String source;

  const MatchedArticle({
    required this.id,
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    required this.keywords,
    required this.fetchedAt,
    this.source = '연합뉴스',
  });

  MatchedArticle copyWith({List<String>? keywords}) {
    return MatchedArticle(
      id: id,
      title: title,
      link: link,
      pubDate: pubDate,
      description: description,
      keywords: keywords ?? this.keywords,
      fetchedAt: fetchedAt,
      source: source,
    );
  }

  factory MatchedArticle.fromJson(Map<String, dynamic> json) {
    return MatchedArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      link: json['link'] as String,
      pubDate: DateTime.parse(json['pubDate'] as String),
      description: json['description'] as String? ?? '',
      keywords:
          (json['keywords'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      // source 필드가 없던 시절에 저장된 기사는 연합뉴스로 본다.
      source: json['source'] as String? ?? '연합뉴스',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'pubDate': pubDate.toIso8601String(),
      'description': description,
      'keywords': keywords,
      'fetchedAt': fetchedAt.toIso8601String(),
      'source': source,
    };
  }
}
