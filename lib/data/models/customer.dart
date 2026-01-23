class Customer {
  final String phoneNumber;
  final String name;
  final String address;
  final String? dateOfBirth;
  final String? job;
  final int transactionCount;

  const Customer({
    required this.phoneNumber,
    required this.name,
    required this.address,
    this.dateOfBirth,
    this.job,
    this.transactionCount = 0,
  });

  Customer copyWith({
    String? phoneNumber,
    String? name,
    String? address,
    String? dateOfBirth,
    String? job,
    int? transactionCount,
  }) {
    return Customer(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      job: job ?? this.job,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'job': job,
      'transactionCount': transactionCount,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      dateOfBirth: json['dateOfBirth'] as String?,
      job: json['job'] as String?,
      transactionCount: json['transactionCount'] as int? ?? 0,
    );
  }
}
