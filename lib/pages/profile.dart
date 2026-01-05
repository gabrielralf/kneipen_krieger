import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/my_button.dart';

class ProfilePage extends StatelessWidget {
	const ProfilePage({super.key});

	@override
	Widget build(BuildContext context) {
		return ColoredBox(
			color: Colors.white,
			child: SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Text(
								'Profile',
								style: TextStyle(
									fontSize: 20,
									fontWeight: FontWeight.w600,
								),
							),
							const SizedBox(height: 12),
							MyButton(
								text: 'Logout',
								onTap: () async {
									try {
										await Supabase.instance.client.auth.signOut();
									} catch (e) {
										if (!context.mounted) return;
										ScaffoldMessenger.of(context).showSnackBar(
											SnackBar(content: Text('Logout failed: ${e.toString()}')),
										);
									}
								},
							),
						],
					),
				),
			),
		);
	}
}
