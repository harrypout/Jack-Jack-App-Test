import 'package:jackjack/models/faq.dart';

final faqs = [
  FAQ(
    question: 'How do I connect?',
    answer:
        'Power on your Jack Jack, enable Bluetooth and allow Bluetooth access. Open Connect Device and choose your Jack Jack. Keep it nearby during setup.',
  ),
  FAQ(
    question: 'Is an internet connection needed?',
    answer:
        'No. Sound levels, settings and alert history work locally over Bluetooth.',
  ),
  FAQ(
    question: 'What triggers a sound alert?',
    answer:
        'The Jack Jack measures sound level. Sound above your threshold for about two seconds starts an alert window lasting two minutes. Brief quiet gaps are allowed during confirmation. The app repeats alerts at your selected interval during that window, even if the room becomes quiet.',
  ),
  FAQ(
    question: 'Does it identify crying or monitor breathing?',
    answer:
        'It measures sound level; it does not classify crying, breathing or movement.',
  ),
  FAQ(
    question: 'Can I listen to live audio?',
    answer:
        'Live listening is not available in this version. The meter shows sound-level readings from your Jack Jack.',
  ),
  FAQ(
    question: 'How should I set the threshold?',
    answer:
        'Compare the meter with normal sounds in your room, then set the threshold on that device’s card. The saved value is confirmed by the Jack Jack. Readings depend on the microphone and calibration.',
  ),
  FAQ(
    question: 'What does Alerts off do?',
    answer:
        'It stops phone notifications, sound and vibration for that Jack Jack. Detected events continue to appear in history while connected.',
  ),
  FAQ(
    question: 'How does battery monitoring work?',
    answer:
        'The app checks the connected Jack Jack’s reported battery level and records one warning below 20% per low-battery episode. The warning resets after the level reaches 25%. Battery updates can be delayed while the phone is suspended.',
  ),
  FAQ(
    question: 'Will I receive alerts with the screen locked?',
    answer:
        'Keep the Jack Jack connected, Bluetooth enabled and notification permission allowed. Phone Focus and silent settings can affect notification presentation. Reopen Jack Jack after force-closing it or restarting the phone and check the connection status.',
  ),
  FAQ(
    question: 'What if the device is disconnected?',
    answer:
        'Bring the phone and Jack Jack closer and check Bluetooth and power. Jack Jack retries enabled connections. A disconnected or unavailable meter is not evidence of a quiet room.',
  ),
  FAQ(
    question: 'How much history is stored?',
    answer:
        'Up to 30 days or the newest 1,000 events, whichever limit is reached first. History is stored on your phone and can be cleared in the app.',
  ),
  FAQ(
    question: 'Is audio recorded or uploaded?',
    answer:
        'The app receives sound-level readings and alert events, not audio recordings. It keeps alert history locally.',
  ),
  FAQ(
    question: 'Where should I place the Jack Jack?',
    answer:
        'Keep the device and charging cables outside your baby’s reach. Follow the supplied hardware instructions. Jack Jack does not replace adult supervision.',
  ),
];
