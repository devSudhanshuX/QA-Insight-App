import 'package:flutter/material.dart';
import 'package:qa_insight_hub/core/models/auth_session.dart';
import 'package:qa_insight_hub/features/auth/presentation/view_models/login_view_model.dart';
import 'package:qa_insight_hub/features/home/presentation/views/q_dashboard_shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final LoginViewModel _viewModel;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel()..addListener(_handleStateChange);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  void _handleStateChange() {
    final AuthSession? session = _viewModel.session;
    if (session != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QDashboardShell(session: session)),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _viewModel
      ..removeListener(_handleStateChange)
      ..dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _viewModel.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          final value = _animationController.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + value, -1),
                end: Alignment(1, 1 - value),
                colors: const [
                  Color(0xFF1B1E5B),
                  Color(0xFF0077B6),
                  Color(0xFF00B4D8),
                  Color(0xFF90E0EF),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Card(
                    elevation: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedBuilder(
                        animation: _viewModel,
                        builder: (context, __) {
                          return Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'QA Insight Hub',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B1E5B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Model Name: Q Dashboard',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF395A8A),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Username is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),
                                if (_viewModel.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _viewModel.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _viewModel.isLoading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: _viewModel.isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Login'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Quick Demo Login',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _DemoRoleChip(
                                      label: 'Assembly',
                                      onTap: () => _viewModel.quickDemoLogin('assembly_user'),
                                    ),
                                    _DemoRoleChip(
                                      label: 'QA Rep',
                                      onTap: () => _viewModel.quickDemoLogin('qa_representative'),
                                    ),
                                    _DemoRoleChip(
                                      label: 'Management',
                                      onTap: () => _viewModel.quickDemoLogin('management_viewer'),
                                    ),
                                    _DemoRoleChip(
                                      label: 'Admin',
                                      onTap: () => _viewModel.quickDemoLogin('admin'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoRoleChip extends StatelessWidget {
  const _DemoRoleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.bolt, size: 16),
      onPressed: onTap,
      backgroundColor: const Color(0xFFCAE9FF),
      side: BorderSide.none,
    );
  }
}
