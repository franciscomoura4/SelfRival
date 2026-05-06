class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<dynamic, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Runner',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email};
  }
}