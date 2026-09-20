import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactUsScreen extends StatefulWidget {
  static const String id = 'contact_us_screen';
  const ContactUsScreen({super.key});
  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _feedback = TextEditingController();
  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TestFlight Feedback')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Open Jack Jack in TestFlight and choose Send Beta Feedback. Include what happened, your phone model and the steps to reproduce it. You can prepare your notes here.',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _feedback,
          minLines: 5,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: 'Feedback notes',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _feedback.text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Copied. Paste your notes into TestFlight feedback.',
                  ),
                ),
              );
            }
          },
          child: const Text('Copy feedback'),
        ),
      ],
    ),
  );
}
