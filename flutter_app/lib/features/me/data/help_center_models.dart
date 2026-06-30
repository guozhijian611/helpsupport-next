class HelpCategory {
  const HelpCategory({
    required this.id,
    required this.parentId,
    required this.name,
    required this.description,
    required this.image,
    required this.sort,
  });

  final int id;
  final int parentId;
  final String name;
  final String description;
  final String image;
  final int sort;

  factory HelpCategory.fromJson(Map<String, dynamic> json) {
    return HelpCategory(
      id: _intValue(json['id']),
      parentId: _intValue(json['parent_id']),
      name: _stringValue(json['category_name']),
      description: _stringValue(json['describe']),
      image: _stringValue(json['image']),
      sort: _intValue(json['sort'], fallback: 100),
    );
  }
}

class HelpArticlePage {
  const HelpArticlePage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<HelpArticleSummary> list;
  final int total;
  final int page;
  final int pageSize;

  factory HelpArticlePage.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const HelpArticlePage(list: [], total: 0, page: 1, pageSize: 10);
    }

    return HelpArticlePage(
      list: _list(value['data'], HelpArticleSummary.fromJson),
      total: _intValue(value['total']),
      page: _intValue(value['current_page'], fallback: 1),
      pageSize: _intValue(value['per_page'], fallback: 10),
    );
  }
}

class HelpArticleSummary {
  const HelpArticleSummary({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.author,
    required this.image,
    required this.description,
    required this.views,
    required this.isLink,
    required this.linkUrl,
    required this.createdAt,
  });

  final int id;
  final int categoryId;
  final String title;
  final String author;
  final String image;
  final String description;
  final int views;
  final bool isLink;
  final String linkUrl;
  final String createdAt;

  factory HelpArticleSummary.fromJson(Map<String, dynamic> json) {
    return HelpArticleSummary(
      id: _intValue(json['id']),
      categoryId: _intValue(json['category_id']),
      title: _stringValue(json['title']),
      author: _stringValue(json['author']),
      image: _stringValue(json['image']),
      description: _stringValue(json['describe']),
      views: _intValue(json['views']),
      isLink: _intValue(json['is_link'], fallback: 2) == 1,
      linkUrl: _stringValue(json['link_url']),
      createdAt: _stringValue(json['create_time']),
    );
  }
}

class HelpArticleDetail extends HelpArticleSummary {
  const HelpArticleDetail({
    required super.id,
    required super.categoryId,
    required super.title,
    required super.author,
    required super.image,
    required super.description,
    required super.views,
    required super.isLink,
    required super.linkUrl,
    required super.createdAt,
    required this.content,
    required this.updatedAt,
  });

  final String content;
  final String updatedAt;

  factory HelpArticleDetail.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const HelpArticleDetail(
        id: 0,
        categoryId: 0,
        title: '',
        author: '',
        image: '',
        description: '',
        views: 0,
        isLink: false,
        linkUrl: '',
        createdAt: '',
        content: '',
        updatedAt: '',
      );
    }

    return HelpArticleDetail(
      id: _intValue(value['id']),
      categoryId: _intValue(value['category_id']),
      title: _stringValue(value['title']),
      author: _stringValue(value['author']),
      image: _stringValue(value['image']),
      description: _stringValue(value['describe']),
      views: _intValue(value['views']),
      isLink: _intValue(value['is_link'], fallback: 2) == 1,
      linkUrl: _stringValue(value['link_url']),
      createdAt: _stringValue(value['create_time']),
      content: _stringValue(value['content']),
      updatedAt: _stringValue(value['update_time']),
    );
  }
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic> json) decode) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(decode)
      .toList(growable: false);
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

String _stringValue(Object? value) {
  final text = (value ?? '').toString().trim();
  return text == 'null' ? '' : text;
}
