import '../models/customer.dart';

class CustomerRepository {
  static final CustomerRepository instance = CustomerRepository._();

  CustomerRepository._();

  final List<Customer> _customers = [
    Customer(
      phoneNumber: '081234567890',
      name: 'Budi Santoso',
      address: 'Jalan Merdeka No. 1',
      dateOfBirth: '1990-01-01',
      job: 'Wiraswasta',
      transactionCount: 4, // Next is 5th (Hair Spray)
    ),
    Customer(
      phoneNumber: '089876543210',
      name: 'Siti Aminah',
      address: 'Jalan Mawar No. 10',
      dateOfBirth: '1995-05-15',
      job: 'Karyawan Swasta',
      transactionCount: 9, // Next is 10th (Discount 50%)
    ),
  ];

  Customer? findByPhone(String phone) {
    try {
      return _customers.firstWhere((c) => c.phoneNumber == phone);
    } catch (e) {
      return null;
    }
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
  }

  void incrementTransactionCount(String phone) {
    try {
      final index = _customers.indexWhere((c) => c.phoneNumber == phone);
      if (index != -1) {
        final customer = _customers[index];
        _customers[index] = customer.copyWith(transactionCount: customer.transactionCount + 1);
      }
    } catch (e) {
      // Ignore
    }
  }
}
