import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final VoidCallback onAccept;

  const TermsAndConditionsScreen({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3E4795));
    const hStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    const pStyle = TextStyle(fontSize: 14, height: 1.6);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Terms and Conditions", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3E4795),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("FCM Transport Mobile App – Passenger Interface", style: titleStyle),
                    SizedBox(height: 4),
                    Text("Last Updated: November 6, 2025", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 16),
                    Text("Welcome to the FCM Transport Mobile App (\"the App\"), operated by FCM Transport Corporation (\"we,\" \"our,\" or \"us\"). By downloading, accessing, or using this App, you agree to comply with and be bound by these Terms and Conditions. Please read them carefully before using the App.", style: pStyle),

                    SizedBox(height: 16),
                    Text("1. Purpose of the App", style: hStyle),
                    SizedBox(height: 6),
                    Text("The FCM Transport Mobile App is designed to help passengers:", style: pStyle),
                    _Bullet('Track FCM buses in real time (limited to 3 vehicles at a time)'),
                    _Bullet('Receive official notifications and updates from the admin'),
                    _Bullet('Save favorite locations for easier access'),
                    _Bullet('View trip history and recent tracking activity'),
                    Text('This App is intended solely for passenger information and convenience purposes.', style: pStyle),

                    SizedBox(height: 16),
                    Text("2. Acceptance of Terms", style: hStyle),
                    SizedBox(height: 6),
                    Text("By using this App, you acknowledge that you have read, understood, and agreed to these Terms. If you do not agree, please uninstall and discontinue using the App.", style: pStyle),

                    SizedBox(height: 16),
                    Text("3. User Responsibilities", style: hStyle),
                    SizedBox(height: 6),
                    _Bullet("Attempt to interfere with, hack, or disrupt the App’s operation or servers."),
                    _Bullet("Use the App to collect, share, or distribute false or harmful data."),
                    _Bullet("Misuse the App for any purpose other than its intended public service use."),

                    SizedBox(height: 16),
                    Text("4. Location Data", style: hStyle),
                    SizedBox(height: 6),
                    Text("The App may request access to your device’s location to display accurate routes, track nearby vehicles, and show personalized route updates. You may disable location access through your device settings; however, some features (such as setting destinations) may not function properly without it.", style: pStyle),

                    SizedBox(height: 16),
                    Text("5. Notifications", style: hStyle),
                    SizedBox(height: 6),
                    Text("By using the App, you agree to receive notifications from FCM Transport, which may include:", style: pStyle),
                    _Bullet('General announcements'),
                    _Bullet('Route and service updates'),
                    _Bullet('System notifications'),
                    _Bullet('Maintenance notices'),
                    Text('These notifications aim to improve your commuting experience and provide timely service information.', style: pStyle),

                    SizedBox(height: 16),
                    Text("6. Account and Data Privacy", style: hStyle),
                    SizedBox(height: 6),
                    Text("The FCM Transport Mobile App does not require user registration and does not collect personal information beyond what is necessary for providing real-time tracking and system functionality. For details on how we handle data, please refer to our Privacy Policy.", style: pStyle),

                    SizedBox(height: 16),
                    Text("7. Accuracy of Information", style: hStyle),
                    SizedBox(height: 6),
                    Text("The real-time tracking data and route information displayed in the App are provided for convenience. While we strive to ensure accuracy, FCM Transport Corporation does not guarantee that all information—such as bus locations or arrival times—is always precise due to possible signal delays or network issues.", style: pStyle),

                    SizedBox(height: 16),
                    Text("8. Intellectual Property", style: hStyle),
                    SizedBox(height: 6),
                    Text("All content, including logos, names, designs, and system features, is the property of FCM Transport Corporation. You may not reproduce, modify, or distribute any part of the App without prior written permission.", style: pStyle),

                    SizedBox(height: 16),
                    Text("9. Limitation of Liability", style: hStyle),
                    SizedBox(height: 6),
                    _Bullet('Inaccurate or delayed tracking data'),
                    _Bullet('App malfunctions or service interruptions'),
                    _Bullet('User reliance on the App’s information'),
                    Text('Use of the App is at your own discretion and risk.', style: pStyle),

                    SizedBox(height: 16),
                    Text("10. App Updates and Availability", style: hStyle),
                    SizedBox(height: 6),
                    Text("We may update, modify, or suspend parts of the App at any time to improve functionality or ensure service reliability. Users are encouraged to keep their app version updated to access the latest features and fixes.", style: pStyle),

                    SizedBox(height: 16),
                    Text("11. Termination of Use", style: hStyle),
                    SizedBox(height: 6),
                    Text("FCM Transport Corporation reserves the right to restrict or terminate access to the App at any time without notice if a user violates these Terms or misuses the service.", style: pStyle),

                    SizedBox(height: 16),
                    Text("12. Changes to These Terms", style: hStyle),
                    SizedBox(height: 6),
                    Text("We may revise these Terms and Conditions periodically. Updates will be posted within the App or on our official website, with a revised “Last Updated” date. Continued use of the App after such updates signifies your acceptance of the new Terms.", style: pStyle),

                    SizedBox(height: 16),
                    Text("13. Contact Us", style: hStyle),
                    SizedBox(height: 6),
                    Text('📧 support@fcmtransport.com', style: pStyle),
                    Text('🌐 FCM Transport - Batangas-Bauan Grand Terminal Corporation facebook page', style: pStyle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E4795),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("I Accept", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6))),
        ],
      ),
    );
  }
}
