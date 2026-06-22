import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bax_logo.dart';

const int kMinorAge = 16;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianEmail = TextEditingController();
  DateTime? _dob;
  bool _acceptTerms = false;
  bool _guardianConsent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _guardianName.dispose();
    _guardianEmail.dispose();
    super.dispose();
  }

  int? get _age {
    if (_dob == null) return null;
    final now = DateTime.now();
    var a = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) {
      a -= 1;
    }
    return a;
  }

  bool get _isMinor => _age != null && _age! < kMinorAge;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (_dob == null) {
      setState(() => _error = 'Please select your date of birth');
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
            dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob!),
            acceptTerms: _acceptTerms,
            guardianName: _isMinor ? _guardianName.text.trim() : null,
            guardianEmail: _isMinor ? _guardianEmail.text.trim() : null,
            guardianConsent: _isMinor ? _guardianConsent : null,
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
                const Center(child: BaxLogo(size: 52)),
                const SizedBox(height: 24),
                const Text('Create your account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
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
                  controller: _password,
                  obscureText: true,
                  decoration:
                      const InputDecoration(hintText: 'Password (min 8 characters)'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of birth'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dob == null
                              ? 'Select your date of birth'
                              : DateFormat('d MMM yyyy').format(_dob!),
                          style: TextStyle(
                              color: _dob == null
                                  ? BaxColors.muted
                                  : BaxColors.text),
                        ),
                        Icon(Icons.calendar_today,
                            size: 18, color: BaxColors.muted),
                      ],
                    ),
                  ),
                ),
                if (_age != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _isMinor
                        ? 'You are under $kMinorAge. A parent or guardian must '
                            'register and consent on your behalf, and parental '
                            'controls will be enabled.'
                        : 'Age $_age — you can register yourself.',
                    style: TextStyle(
                        color: _isMinor ? BaxColors.accent : BaxColors.muted,
                        fontSize: 13),
                  ),
                ],
                if (_isMinor) ...[
                  const SizedBox(height: 16),
                  Text('Parent / guardian details',
                      style: TextStyle(
                          color: BaxColors.text,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _guardianName,
                    decoration:
                        const InputDecoration(hintText: 'Parent / guardian full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _guardianEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        hintText: 'Parent / guardian email'),
                  ),
                  CheckboxListTile(
                    value: _guardianConsent,
                    onChanged: (v) =>
                        setState(() => _guardianConsent = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: BaxColors.primary,
                    checkColor: Colors.black,
                    title: Text(
                      'I am the parent/guardian and I consent to this account '
                      'and to processing the child\'s personal data.',
                      style: TextStyle(color: BaxColors.text, fontSize: 14),
                    ),
                  ),
                ],
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: BaxColors.primary,
                  checkColor: Colors.black,
                  title: Text(
                    'I accept the Terms of Service & Privacy Policy and consent '
                    'to processing of personal data.',
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
