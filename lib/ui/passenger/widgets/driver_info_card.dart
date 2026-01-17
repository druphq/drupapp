import 'package:flutter/material.dart';
import '../../../data/models/driver.dart';
import '../../../theme/app_colors.dart';

class DriverInfoCard extends StatelessWidget {
  final Driver driver;
  final String? eta;
  final String? distance;

  const DriverInfoCard({
    super.key,
    required this.driver,
    this.eta,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: driver.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        driver.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                      ),
                    )
                  : const Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        driver.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${driver.totalRides} trips)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${driver.vehicleModel} • ${driver.vehicleNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (eta != null || distance != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (distance != null) ...[
                          const Icon(
                            Icons.directions_car,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (distance != null && eta != null)
                          const SizedBox(width: 12),
                        if (eta != null) ...[
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            eta!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    // Call driver
                  },
                  color: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    // Message driver
                  },
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
