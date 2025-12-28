import 'package:flutter/material.dart';
import 'package:kneipen_krieger/components/input_fields.dart';
import 'package:kneipen_krieger/components/my_button.dart';

import '../components/auth_db.dart';
import 'home.dart';

class RegisterPage extends StatefulWidget {
	const RegisterPage({super.key});

	@override
	State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
	final emailController = TextEditingController();
	final passwordController = TextEditingController();
	final dobController = TextEditingController();

	DateTime? _dateOfBirth;
	bool _isLoading = false;

	@override
	void dispose() {
		emailController.dispose();
		passwordController.dispose();
		dobController.dispose();
		super.dispose();
	}

	bool _isValidEmail(String value) {
		// Simple, practical email check for client-side UX.
		final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
		return emailRegex.hasMatch(value);
	}

	bool _isAtLeast18(DateTime dob, DateTime now) {
		final cutoff = DateTime(now.year - 18, now.month, now.day);
		return !dob.isAfter(cutoff);
	}

	Future<void> _pickDob() async {
		final now = DateTime.now();
		final initialDate = _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
		final picked = await showDatePicker(
			context: context,
			initialDate: initialDate,
			firstDate: DateTime(1900, 1, 1),
			lastDate: now,
		);

		if (picked == null) return;

		setState(() {
			_dateOfBirth = picked;
			dobController.text = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
		});
	}

	Future<void> _register() async {
		if (_isLoading) return;

		final email = emailController.text.trim();
		final password = passwordController.text;
		final dob = _dateOfBirth;

		if (email.isEmpty || password.isEmpty || dob == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please fill in email, password, and birthday.')),
			);
			return;
		}

		if (!_isValidEmail(email)) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please enter a valid email address.')),
			);
			return;
		}

		if (password.length < 8) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Password must be at least 8 characters.')),
			);
			return;
		}

		final now = DateTime.now();
		if (!_isAtLeast18(dob, now)) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('You must be 18+ to use this app.')),
			);
			return;
		}

		setState(() => _isLoading = true);
		try {
			await AuthDb().signUp(
				email: email,
				password: password,
				data: {
					'date_of_birth': dob.toIso8601String(),
				},
			);

			if (!mounted) return;

			// Note: Depending on your Supabase settings, email confirmation may be
			// required before the session becomes active.
			await Navigator.of(context).pushAndRemoveUntil(
				MaterialPageRoute(builder: (_) => const HomePage()),
				(route) => false,
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Registration failed: ${e.toString()}')),
			);
		} finally {
			if (mounted) setState(() => _isLoading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: SingleChildScrollView(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const SizedBox(height: 50),

							Image.asset(
								'lib/images/logo.png',
								width: 120,
								height: 120,
								fit: BoxFit.contain,
							),

							const SizedBox(height: 50),

							const Text(
								'Register',
								style: TextStyle(
									color: Colors.black,
									fontSize: 16,
								),
							),

							const SizedBox(height: 25),

							InputField(
								controller: emailController,
								hintText: 'Email',
								obscureText: false,
							),

							InputField(
								controller: passwordController,
								hintText: 'Password',
								obscureText: true,
							),

							GestureDetector(
								onTap: _pickDob,
								child: AbsorbPointer(
									child: InputField(
										controller: dobController,
										hintText: 'Birthday (DD.MM.YYYY)',
										obscureText: false,
									),
								),
							),

							const SizedBox(height: 25),

							MyButton(
								onTap: _isLoading ? null : _register,
								text: 'Register',
							),

							if (_isLoading) ...[
								const SizedBox(height: 16),
								const CircularProgressIndicator(),
							],
						],
					),
				),
			),
		);
	}
}
