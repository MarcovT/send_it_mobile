import 'package:flutter/material.dart';
import '../models/court.dart';

class CourtListItem extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;

  const CourtListItem({
    super.key,
    required this.court,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Court icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.indigo.shade100,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.sports_tennis_sharp,
                color: Colors.indigo.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Court details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.videocam,
                        color: Colors.grey.shade600,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View videos & schedule',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}