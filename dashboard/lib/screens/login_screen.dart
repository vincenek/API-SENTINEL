import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;

  // Registration fields
  final _companyNameController = TextEditingController();
  String _primaryGateway = 'stripe';
  String _secondaryGateway = 'paypal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(32),
              elevation: 8,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.security,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'API Sentinel',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Create your account'
                            : 'Sign in to your dashboard',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_isRegisterMode) ...[
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (_isRegisterMode && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _primaryGateway,
                          decoration: const InputDecoration(
                            labelText: 'Primary Gateway',
                            prefixIcon: Icon(Icons.account_balance),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'stripe', child: Text('Stripe')),
                            DropdownMenuItem(
                                value: 'paypal', child: Text('PayPal')),
                            DropdownMenuItem(
                                value: 'square', child: Text('Square')),
                            DropdownMenuItem(
                                value: 'braintree', child: Text('Braintree')),
                          ],
                          onChanged: (value) =>
                              setState(() => _primaryGateway = value!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _secondaryGateway,
                          decoration: const InputDecoration(
                            labelText: 'Secondary Gateway',
                            prefixIcon: Icon(Icons.sync_alt),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'stripe', child: Text('Stripe')),
                            DropdownMenuItem(
                                value: 'paypal', child: Text('PayPal')),
                            DropdownMenuItem(
                                value: 'square', child: Text('Square')),
                            DropdownMenuItem(
                                value: 'braintree', child: Text('Braintree')),
                          ],
                          onChanged: (value) =>
                              setState(() => _secondaryGateway = value!),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _isRegisterMode ? 'Create Account' : 'Sign In'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                          });
                        },
                        child: Text(
                          _isRegisterMode
                              ? 'Already have an account? Sign in'
                              : 'Don\'t have an account? Register',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    bool success;

    if (_isRegisterMode) {
      success = await auth.register(
        companyName: _companyNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        primaryGateway: _primaryGateway,
        secondaryGateway: _secondaryGateway,
      );
    } else {
      success = await auth.login(
        _emailController.text,
        _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isRegisterMode ? 'Registration failed' : 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }
}
