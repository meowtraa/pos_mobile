import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pos/pos_page.dart';
import 'login_view_model.dart';

/// Login Page
/// Authentication screen for user login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await viewModel.login();
      if (success && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const POSPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Row(
            children: [
              // Left - Branding Section
              if (size.width > 800)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Image.asset(
                            'assets/images/logo.PNG',
                            height: 80,
                            errorBuilder: (_, __, ___) => Icon(Icons.content_cut, size: 80, color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Macho\'s Barbershop',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Point of Sale System',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Right - Login Form Section
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mobile Logo
                            if (size.width <= 800) ...[
                              Center(
                                child: Image.asset(
                                  'assets/images/logo.PNG',
                                  height: 60,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.content_cut, size: 60, color: colorScheme.primary),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Title
                            Text(
                              'Selamat Datang',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Masuk ke akun Anda untuk melanjutkan',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 32),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: viewModel.setEmail,
                              validator: viewModel.validateEmail,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'contoh@email.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: viewModel.obscurePassword,
                              onChanged: viewModel.setPassword,
                              validator: viewModel.validatePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  onPressed: viewModel.togglePasswordVisibility,
                                  icon: Icon(
                                    viewModel.obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Forgot password
                                },
                                child: const Text('Lupa Password?'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Error Message
                            if (viewModel.isError)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viewModel.errorMessage ?? 'Error',
                                        style: TextStyle(color: colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Login Button
                            FilledButton(
                              onPressed: viewModel.isLoading ? null : () => _handleLogin(viewModel),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: viewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Masuk'),
                            ),
                            const SizedBox(height: 24),

                            // Demo Login Button
                            OutlinedButton.icon(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () {
                                      viewModel.fillDemoCredentials();
                                      _emailController.text = LoginViewModel.demoEmail;
                                      _passwordController.text = LoginViewModel.demoPassword;
                                    },
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Login Demo (24 Jam)'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Demo Info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Akun demo: ${LoginViewModel.demoEmail}\nPassword: ${LoginViewModel.demoPassword}\nSession berlaku 24 jam',
                                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
