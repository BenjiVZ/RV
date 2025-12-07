class Client {
  final int? id;
  final String fullName;
  final String cedula;
  final String phone;

  Client({
    this.id,
    required this.fullName,
    required this.cedula,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'cedula': cedula,
      'phone': phone,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      fullName: map['fullName'],
      cedula: map['cedula'],
      phone: map['phone'],
    );
  }

  Client copyWith({
    int? id,
    String? fullName,
    String? cedula,
    String? phone,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      cedula: cedula ?? this.cedula,
      phone: phone ?? this.phone,
    );
  }
}
