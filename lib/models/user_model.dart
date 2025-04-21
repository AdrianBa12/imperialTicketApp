class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final List<String> recentSearches;
  final List<String> favoriteRoutes;
  final DateTime createdAt;


  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    List<String>? recentSearches,
    List<String>? favoriteRoutes,
    DateTime? createdAt,
  })  : recentSearches = recentSearches ?? [],
        favoriteRoutes = favoriteRoutes ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'], 
      recentSearches: (json['recentSearches'] as List?)?.map((e) => e.toString()).toList() ?? [],
      favoriteRoutes: (json['favoriteRoutes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'recentSearches': recentSearches,
      'favoriteRoutes': favoriteRoutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    List<String>? recentSearches,
    List<String>? favoriteRoutes,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      recentSearches: recentSearches ?? this.recentSearches,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
