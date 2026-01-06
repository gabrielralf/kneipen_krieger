import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../components/input_fields.dart';
import '../components/my_button.dart';

class PriceSuggestionPage extends StatefulWidget {
	const PriceSuggestionPage({super.key});

	@override
	State<PriceSuggestionPage> createState() => _PriceSuggestionPageState();
	}

class _PriceSuggestionPageState extends State<PriceSuggestionPage> {
	final _barNameController = TextEditingController();
	final _streetNameController = TextEditingController();
	final _streetNumberController = TextEditingController();

	final _imagePicker = ImagePicker();
	XFile? _photo;

	String? _drinkType;
	double _price = 5.0;
	bool _isSaving = false;

	@override
	void dispose() {
		_barNameController.dispose();
		_streetNameController.dispose();
		_streetNumberController.dispose();
		super.dispose();
	}

	Future<void> _pickFromGallery() async {
		final picked = await _imagePicker.pickImage(
			source: ImageSource.gallery,
			imageQuality: 85,
		);
		if (picked == null) return;
		setState(() => _photo = picked);
	}

	Future<void> _takePhoto() async {
		final picked = await _imagePicker.pickImage(
			source: ImageSource.camera,
			imageQuality: 85,
		);
		if (picked == null) return;
		setState(() => _photo = picked);
	}

	Future<void> _saveAndPost() async {
		if (_isSaving) return;

		final barName = _barNameController.text.trim();
		final streetName = _streetNameController.text.trim();
		final streetNumber = _streetNumberController.text.trim();

		if (_drinkType == null || _drinkType!.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please select a drink type.')),
			);
			return;
		}
		if (barName.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please enter the bar name.')),
			);
			return;
		}
		if (streetName.isEmpty || streetNumber.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please enter street name and number.')),
			);
			return;
		}
		if (_photo == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please upload a photo.')),
			);
			return;
		}

		setState(() => _isSaving = true);
		try {
			// Placeholder: later save to backend.
			await Future<void>.delayed(const Duration(milliseconds: 200));

			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Saved & posted.')),
			);
			setState(() {
				_drinkType = null;
				_price = 5.0;
				_photo = null;
				_barNameController.clear();
				_streetNameController.clear();
				_streetNumberController.clear();
			});
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Save failed: ${e.toString()}')),
			);
		} finally {
			if (mounted) setState(() => _isSaving = false);
		}
	}

	InputDecoration _dropdownDecoration(String hint) {
		return InputDecoration(
			enabledBorder: const OutlineInputBorder(
				borderSide: BorderSide(color: Colors.white),
			),
			focusedBorder: OutlineInputBorder(
				borderSide: BorderSide(color: Colors.grey.shade400),
			),
			fillColor: Colors.grey.shade200,
			filled: true,
			hintText: hint,
		);
	}

	@override
	Widget build(BuildContext context) {
		final formattedPrice = _price.toStringAsFixed(2);

		return ColoredBox(
			color: Colors.white,
			child: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.symmetric(vertical: 16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							const Padding(
								padding: EdgeInsets.symmetric(horizontal: 25),
								child: Text(
									'Price suggestion',
									style: TextStyle(
										fontSize: 20,
										fontWeight: FontWeight.w600,
									),
								),
							),
							const SizedBox(height: 16),

							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 25),
								child: DropdownButtonFormField<String>(
									value: _drinkType,
									decoration: _dropdownDecoration('Drink type'),
									items: const [
										DropdownMenuItem(value: 'beer', child: Text('beer')),
										DropdownMenuItem(value: 'whine', child: Text('whine')),
										DropdownMenuItem(value: 'cocktail', child: Text('cocktail')),
										DropdownMenuItem(value: 'whiskey', child: Text('whiskey')),
										DropdownMenuItem(value: 'other', child: Text('other')),
									],
									onChanged: (value) => setState(() => _drinkType = value),
								),
							),
							const SizedBox(height: 12),

							InputField(
								controller: _barNameController,
								hintText: 'Bar name',
								obscureText: false,
							),
							const SizedBox(height: 12),

							InputField(
								controller: _streetNameController,
								hintText: 'Street name',
								obscureText: false,
							),
							const SizedBox(height: 12),

							InputField(
								controller: _streetNumberController,
								hintText: 'Street number',
								obscureText: false,
							),
							const SizedBox(height: 18),

							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 25),
								child: Text(
									'Price: $formattedPrice €',
									style: const TextStyle(
										fontSize: 16,
										fontWeight: FontWeight.w500,
									),
								),
							),
							Slider(
								value: _price,
								min: 1.0,
								max: 100.0,
								divisions: 198,
								onChanged: (value) {
									final rounded = (value * 2).round() / 2;
									setState(() => _price = rounded);
								},
							),
							const SizedBox(height: 8),

							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 25),
								child: Row(
									children: [
										Expanded(
											child: OutlinedButton(
												onPressed: _takePhoto,
												child: const Text('Camera'),
											),
										),
										const SizedBox(width: 12),
										Expanded(
											child: OutlinedButton(
												onPressed: _pickFromGallery,
												child: const Text('Gallery'),
											),
										),
									],
								),
							),
							const SizedBox(height: 12),

							if (_photo != null)
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 25),
									child: ClipRRect(
										borderRadius: BorderRadius.circular(8),
										child: Image.file(
											File(_photo!.path),
											height: 180,
											width: double.infinity,
											fit: BoxFit.cover,
										),
									),
								),
							if (_photo != null) const SizedBox(height: 18),

							MyButton(
								text: _isSaving ? 'Saving...' : 'Save&Post',
								onTap: _isSaving ? null : _saveAndPost,
							),
							const SizedBox(height: 16),
						],
					),
				),
			),
		);
	}
}
