class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final List<String> rideHistory;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.rideHistory = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      rideHistory: List<String>.from(json['rideHistory'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'rideHistory': rideHistory,
    };
  }
}
