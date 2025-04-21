
class User {
  final int id;
  final String? username;
  final String? email;
  
  User({
    required this.id,
    this.username,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {

    final attributes = json['attributes'] as Map<String, dynamic>? ?? json; 

    return User(
      id: json['id'] as int,
      username: attributes['username'] as String?,
      email: attributes['email'] as String?,
    );
  }
}