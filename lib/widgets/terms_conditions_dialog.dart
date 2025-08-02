import 'package:flutter/material.dart';

class TermsConditionsDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TermsConditionsDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to SEND-IT!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please read and accept our terms to continue.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Terms sections
                      _buildTermsSection(
                        '1. Acceptance of Terms',
                        'By using SEND-IT, you agree to be bound by these Terms & Conditions.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        '2. Use of the Service',
                        'You agree to use the service responsibly and in accordance with all applicable laws.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        '3. Location Data',
                        'SEND-IT may request access to your location to provide nearby club recommendations. This data is used solely for improving your experience.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        '4. Privacy & Video Recording',
                        'SEND-IT records videos when you activate the recording feature during play. These videos are stored securely on our servers for 30 days only, after which they are automatically deleted. You can download and view your videos at any time during this period. We dont share videos but users can freely share videos as they please ',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        '5. Liability',
                        'SEND-IT is provided "as is" without warranties. We are not liable for any damages arising from your use of the service. By using the video recording feature, you acknowledge that videos may be accessible to other users of the app, and you assume full responsibility for any content you record. As this is a free app available to the public, we cannot guarantee the privacy or security of recorded content beyond our 30-day storage policy.',
                      ),
                      
                      const SizedBox(height: 20),
                      Text(
                        'By tapping "Accept", you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onDecline,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Decline',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAccept,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}