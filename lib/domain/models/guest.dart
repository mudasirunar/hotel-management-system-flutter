final class Guest {
  const Guest({
    required this.id,
    required this.name,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String cnic;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
}
