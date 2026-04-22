import 'package:flutter/material.dart';

import '../models.dart';
import 'confirmation_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final String service;

  const BookingFormScreen({super.key, required this.service});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  // Screen state: the form belongs to this screen.
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // Simulated delay so students can observe a loading state.
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    final booking = BookingDraft(
      service: widget.service,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    setState(() {
      isSubmitting = false;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected service',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Chip(label: Text(widget.service)),
              const SizedBox(height: 24),
              Text(
                'Your details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Email is required';
                  }
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Confirm booking'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
