import 'package:jackjack/models/faq.dart';

List<FAQ> faqs = [
  // Getting Started
  FAQ(
    question: "How do I set up the Jack Jack monitor?",
    answer:
        "Plug in the device, download the Jack Jack app, and follow the in-app pairing instructions via Bluetooth. The process takes less than 2 minutes.",
  ),
  FAQ(
    question: "Does Jack Jack require Wi-Fi?",
    answer:
        "No, Jack Jack uses Bluetooth Low Energy (BLE) to connect to your phone. No Wi-Fi or internet is needed for core functionality.",
  ),

  // Functionality
  FAQ(
    question: "What does the Jack Jack monitor do?",
    answer:
        "It listens for key sounds (like crying or sudden noise spikes) and sends real-time alerts to your phone, helping you monitor your baby’s sleep from anywhere nearby.",
  ),
  FAQ(
    question: "Does it monitor breathing or movement?",
    answer:
        "No. Jack Jack is sound-based only. It’s designed to be simple, low-intervention, and focused on sleep-related sounds.",
  ),
  FAQ(
    question: "How far away can I be from the device?",
    answer:
        "Typical range is 10–15 meters indoors, depending on walls and interference.",
  ),

  // Notifications & Sensitivity
  FAQ(
    question: "How do alerts work?",
    answer:
        "The app will notify you when specific sound thresholds are crossed. You can adjust the sensitivity in the app settings.",
  ),
  FAQ(
    question: "Can I adjust what sounds trigger an alert?",
    answer:
        "Yes, you can fine-tune detection for cry-like sounds or general loud noises.",
  ),

  // Power & Battery
  FAQ(
    question: "How long does the battery last?",
    answer:
        "Jack Jack runs for ~24–36 hours on a single charge. You’ll receive battery alerts through the app.",
  ),
  FAQ(
    question: "Can I use it while charging?",
    answer: "Yes, it can operate while plugged in via USB-C.",
  ),

  // Troubleshooting
  FAQ(
    question: "My app isn’t connecting—what should I do?",
    answer:
        "Ensure Bluetooth is enabled, the device is powered on, and you’re within range. You can also try restarting both the app and device.",
  ),
  FAQ(
    question: "I’m not receiving alerts—why?",
    answer:
        "Check notification settings in the app and on your phone. Make sure the app has Bluetooth and notification permissions enabled.",
  ),

  // Privacy & Safety
  FAQ(
    question: "Is any audio stored or uploaded?",
    answer:
        "No. Audio is processed locally on the device and never recorded or sent to the cloud.",
  ),
  FAQ(
    question: "Is Jack Jack safe for my baby?",
    answer:
        "Yes. It emits no radiation, has no cameras, and complies with relevant safety standards.",
  ),
];
