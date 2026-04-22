import 'package:flutter/material.dart';

import 'booking_form_screen.dart';

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  // Local state: this value belongs to this screen only.
  String selectedService = 'Cleaning';

  final List<String> services = const [
    'Cleaning',
    'Repair',
    'Consultation',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Rival'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a service',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen starts as a static layout and then becomes interactive through local state.',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final service = services[index];
                  final isSelected = service == selectedService;

                  return Card(
                    elevation: isSelected ? 3 : 0,
                    child: ListTile(
                      title: Text(service),
                      subtitle: Text(
                        isSelected
                            ? 'Currently selected'
                            : 'Tap to select this service',
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      onTap: () {
                        setState(() {
                          selectedService = service;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingFormScreen(
                        service: selectedService,
                      ),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
