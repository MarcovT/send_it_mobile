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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Court image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  court.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.sports_tennis, color: Colors.white),
                    );
                  },
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(court.address),
                    const SizedBox(height: 4),
                    Text(
                      '${court.distance.toStringAsFixed(1)} km away',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}