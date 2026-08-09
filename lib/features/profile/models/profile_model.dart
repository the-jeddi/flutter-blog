class Profile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'displayName': displayName, 'avatarUrl': avatarUrl};
  }
}
