class Quote {
  final String text;
  final String author;
  final List<int> gradientColors;
  final String imageUrl;

  Quote({
    required this.text,
    required this.author,
    required this.gradientColors,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'author': author,
        'gradientColors': gradientColors,
        'imageUrl': imageUrl,
      };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'],
        author: json['author'],
        gradientColors: List<int>.from(json['gradientColors']),
        imageUrl: json['imageUrl'],
      );
}
