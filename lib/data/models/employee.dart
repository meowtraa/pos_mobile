/// Employee Model
/// Represents an employee/staff member
class Employee {
  final String id;
  final String name;

  const Employee({required this.id, required this.name});

  /// Dummy employees for demo
  static List<Employee> get dummyEmployees => const [
    Employee(id: '1', name: 'Budi Barber'),
    Employee(id: '2', name: 'Andi Stylist'),
    Employee(id: '3', name: 'Rudi Cutter'),
  ];
}
