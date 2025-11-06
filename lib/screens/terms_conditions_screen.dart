import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final VoidCallback onAccept;

  const TermsAndConditionsScreen({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Terms and Conditions"),
        backgroundColor: const Color(0xFF3E4795),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text('''
FCM Transport Mobile App – Passenger Interface
Last Updated: November 6, 2025

Welcome to the FCM Transport Mobile App (“the App”), operated by FCM Transport Corporation (“we,” “our,” or “us”). By downloading, accessing, or using this App, you agree to comply with and be bound by these Terms and Conditions. Please read them carefully before using the App.

1. Purpose of the App
The FCM Transport Mobile App is designed to help passengers:
• Track FCM buses in real time (limited to 3 vehicles at a time)
• Receive official notifications and updates from the admin
• Save favorite locations for easier access
• View trip history and recent tracking activity
This App is intended solely for passenger information and convenience purposes.

2. Acceptance of Terms
By using this App, you acknowledge that you have read, understood, and agreed to these Terms. If you do not agree, please uninstall and discontinue using the App.

3. User Responsibilities
You agree to use the App only for lawful, personal, and non-commercial purposes. You must not:
• Attempt to interfere with, hack, or disrupt the App’s operation or servers.
• Use the App to collect, share, or distribute false or harmful data.
• Misuse the App for any purpose other than its intended public service use.

4. Location Data
The App may request access to your device’s location to display accurate routes, track nearby vehicles, and show personalized route updates.
You may disable location access through your device settings; however, some features (such as setting destinations) may not function properly without it.

5. Notifications
By using the App, you agree to receive notifications from FCM Transport, which may include:
• General announcements
• Route and service updates
• System notifications
• Maintenance notices
These notifications aim to improve your commuting experience and provide timely service information.

6. Account and Data Privacy
The FCM Transport Mobile App does not require user registration and does not collect personal information beyond what is necessary for providing real-time tracking and system functionality.
For details on how we handle data, please refer to our Privacy Policy.

7. Accuracy of Information
The real-time tracking data and route information displayed in the App are provided for convenience.
While we strive to ensure accuracy, FCM Transport Corporation does not guarantee that all information—such as bus locations or arrival times—is always precise due to possible signal delays or network issues.

8. Intellectual Property
All content, including logos, names, designs, and system features, is the property of FCM Transport Corporation.
You may not reproduce, modify, or distribute any part of the App without prior written permission.

9. Limitation of Liability
FCM Transport Corporation is not liable for any direct, indirect, or consequential damages that may result from:
• Inaccurate or delayed tracking data
• App malfunctions or service interruptions
• User reliance on the App’s information
Use of the App is at your own discretion and risk.

10. App Updates and Availability
We may update, modify, or suspend parts of the App at any time to improve functionality or ensure service reliability.
Users are encouraged to keep their app version updated to access the latest features and fixes.

11. Termination of Use
FCM Transport Corporation reserves the right to restrict or terminate access to the App at any time without notice if a user violates these Terms or misuses the service.

12. Changes to These Terms
We may revise these Terms and Conditions periodically. Updates will be posted within the App or on our official website, with a revised “Last Updated” date. Continued use of the App after such updates signifies your acceptance of the new Terms.

13. Contact Us
For questions, concerns, or technical support, please contact:
📧 support@fcmtransport.com
🌐 FCM Transport - Batangas-Bauan Grand Terminal Corporation Facebook page
''', style: TextStyle(fontSize: 16, height: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E4795),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "I Accept",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
