class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  Map<String, dynamic> toMap() {
    return {'text': text, 'author': author};
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(text: map['text'], author: map['author']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote && text == other.text && author == other.author;

  @override
  int get hashCode => text.hashCode ^ author.hashCode;
}