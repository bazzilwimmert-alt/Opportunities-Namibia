import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bax_logo.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _acceptTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_acceptTerms) {
      setState(() => _error = 'Please accept the Terms to continue');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().signup(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            acceptTerms: _acceptTerms,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BaxLogo(size: 44)),
                const SizedBox(height: 24),
                const Text('Create your account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Register, pay your membership and unlock every vacancy.',
                    style: TextStyle(color: BaxColors.muted)),
                const SizedBox(height: 20),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(hintText: 'Phone number (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      hintText: 'Password (min 8 characters)'),
                ),
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: BaxColors.primary,
                  checkColor: Colors.black,
                  title: Text(
                    'I accept the Terms of Service & Privacy Policy, consent to '
                    'processing of my personal data, and understand that '
                    'screenshots of vacancies are prohibited.',
                    style: TextStyle(color: BaxColors.text, fontSize: 14),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
