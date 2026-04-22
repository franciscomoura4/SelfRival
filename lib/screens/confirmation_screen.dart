import 'package:flutter/material.dart';

import '../models.dart';

class ConfirmationScreen extends StatelessWidget {
  final BookingDraft booking;

  const ConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking confirmed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service: ${booking.service}'),
                    const SizedBox(height: 8),
                    Text('Name: ${booking.name}'),
                    const SizedBox(height: 8),
                    Text('Email: ${booking.email}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Use the back button to explore how state behaves when navigating to previous screens.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to form'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
