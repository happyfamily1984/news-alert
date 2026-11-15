/// 키워드와 매칭된 뉴스 기사 한 건.
///
/// [id]는 RSS guid(기사 고유 주소)이며 중복 제거 기준이다.
/// [keywords]는 이 기사와 매칭된 키워드 목록이다 (여러 키워드 매칭 가능).
class MatchedArticle {
  final String id;
  final String title;
  final String link;
  final DateTime pubDate;
  final String description;
  final List<String> keywords;
  final DateTime fetchedAt;

  const MatchedArticle({
    required this.id,
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    required this.keywords,
    required this.fetchedAt,
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
    };
  }
}
