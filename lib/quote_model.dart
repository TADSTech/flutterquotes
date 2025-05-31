class Quote {
  final String text;
  final String author;
  final List<int> gradientColors;
  final String imageUrl;
  final String category;

  Quote({
    required this.text,
    required this.author,
    required this.gradientColors,
    required this.imageUrl,
    this.category = 'General',
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'author': author,
        'gradientColors': gradientColors,
        'imageUrl': imageUrl,
        'category': category,
      };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'],
        author: json['author'],
        gradientColors: List<int>.from(json['gradientColors']),
        imageUrl: json['imageUrl'],
        category: json['category'] ?? 'General',
      );
}
