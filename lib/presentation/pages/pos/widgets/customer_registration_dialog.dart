import 'package:flutter/material.dart';
import '../../../../data/models/customer.dart';
import '../../../../data/repositories/customer_repository.dart';

class CustomerRegistrationDialog extends StatefulWidget {
  final String phoneNumber;

  const CustomerRegistrationDialog({super.key, required this.phoneNumber});

  static Future<Customer?> show(BuildContext context, String phoneNumber) {
    return showDialog<Customer>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerRegistrationDialog(phoneNumber: phoneNumber),
    );
  }

  @override
  State<CustomerRegistrationDialog> createState() => _CustomerRegistrationDialogState();
}

class _CustomerRegistrationDialogState extends State<CustomerRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _jobController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      // YYYY-MM-DD
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _dobController.text = formatted;
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final customer = Customer(
        phoneNumber: widget.phoneNumber,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
        job: _jobController.text.trim().isNotEmpty ? _jobController.text.trim() : null,
      );

      // Save to dummy repository
      CustomerRepository.instance.addCustomer(customer);

      Navigator.pop(context, customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Registrasi Member Baru',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Phone Number (Read only)
                TextFormField(
                  initialValue: widget.phoneNumber,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp *',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // DOB
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                // Job
                TextFormField(
                  controller: _jobController,
                  decoration: const InputDecoration(
                    labelText: 'Pekerjaan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _submit, child: const Text('Simpan')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
