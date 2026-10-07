/// A customer's local traveler contact profile.
final class TravelerProfile {
  const TravelerProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory TravelerProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? 'default_traveler';
    final name = json['name'] as String? ?? '';
    final phone = json['phone'] as String? ?? '';
    final email = json['email'] as String?;

    return TravelerProfile(
      id: id.trim(),
      name: name.trim(),
      phone: phone.trim(),
      email: email?.trim().isEmpty ?? true ? null : email!.trim(),
    );
  }

  final String id;
  final String name;
  final String phone;
  final String? email;

  TravelerProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
  }) => TravelerProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    if (email != null) 'email': email,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelerProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, phone, email);
}
