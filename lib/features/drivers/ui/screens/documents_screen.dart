import 'dart:io';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _documentsData;
  String? _uploadingType;

  final ImagePicker _picker = ImagePicker();

  /// All document types the API expects
  static const List<Map<String, String>> _documentTypes = [
    {'type': 'profile_photo', 'label': 'Profile Photo'},
    {'type': 'drivers_license', 'label': "Driver's License"},
    {'type': 'national_id', 'label': 'National ID'},
    {'type': 'vehicle_registration', 'label': 'Vehicle Registration'},
    {'type': 'vehicle_photo_external', 'label': 'Vehicle Photo (External)'},
    {'type': 'vehicle_photo_internal', 'label': 'Vehicle Photo (Internal)'},
    {'type': 'insurance', 'label': 'Insurance'},
    {'type': 'vehicle_inspection', 'label': 'Vehicle Inspection'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final data =
        await ref.read(driverNotifierProvider.notifier).fetchDocuments();
    setState(() {
      _documentsData = data;
      _isLoading = false;
    });
  }

  Future<void> _uploadDocument(String type, String label) async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingType = type);

    final success = await ref
        .read(driverNotifierProvider.notifier)
        .uploadDocument(documentFile: File(picked.path), type: type);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '$label uploaded successfully!'
                : ref.read(driverNotifierProvider).errorMessage ??
                    'Failed to upload $label',
          ),
          backgroundColor: success ? AppColors.success : AppColors.warning,
        ),
      );
    }

    setState(() => _uploadingType = null);
    if (success) await _loadDocuments();
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.c20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(16),
              Text(
                'Select Source',
                style: TextStyles.t1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.accent),
                title: Text('Gallery', style: TextStyles.t1.copyWith(fontSize: 16)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accent),
                title: Text('Camera', style: TextStyles.t1.copyWith(fontSize: 16)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.surface,
        title: Text('Documents', style: TextStyles.t1),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _loadDocuments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    _buildSummaryCard(),
                    const Gap(16),

                    // Documents list
                    _buildDocumentsList(),
                    const Gap(32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final uploadedCount = _documentsData?['uploadedCount'] as int? ?? 0;
    final requiredCount = _documentsData?['requiredCount'] as int? ?? 0;
    final verificationStatus =
        _documentsData?['verificationStatus'] as String? ?? 'incomplete';
    final missingDocs =
        (_documentsData?['missingDocuments'] as List<dynamic>?) ?? [];

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (verificationStatus) {
      case 'verified':
        statusColor = AppColors.success;
        statusLabel = 'Verified';
        statusIcon = Icons.verified;
        break;
      case 'pending_review':
        statusColor = Colors.orange;
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_top;
        break;
      case 'rejected':
        statusColor = AppColors.warning;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusLabel = 'Incomplete';
        statusIcon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Corners.c8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Verification',
                      style: TextStyles.t1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Corners.c4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: requiredCount > 0 ? uploadedCount / requiredCount : 0,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 6,
            ),
          ),
          const Gap(8),
          Text(
            '$uploadedCount of $requiredCount documents uploaded',
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          // Missing documents
          if (missingDocs.isNotEmpty) ...[
            const Gap(12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missingDocs.map((doc) {
                final label = _formatDocType(doc.toString());
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Corners.c4),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyles.t2.copyWith(
                      fontSize: 11,
                      color: AppColors.warning,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    final uploadedDocs =
        (_documentsData?['documents'] as List<dynamic>?) ?? [];

    // Build a map of uploaded documents by type for quick lookup
    final Map<String, Map<String, dynamic>> uploadedMap = {};
    for (final doc in uploadedDocs) {
      if (doc is Map<String, dynamic>) {
        final type = doc['type'] as String?;
        if (type != null) uploadedMap[type] = doc;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Required Documents',
              style: TextStyles.t1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...List.generate(_documentTypes.length, (index) {
            final docInfo = _documentTypes[index];
            final type = docInfo['type']!;
            final label = docInfo['label']!;
            final uploaded = uploadedMap[type];

            return Column(
              children: [
                if (index > 0) const Divider(height: 1, indent: 20, endIndent: 20),
                _buildDocumentTile(
                  type: type,
                  label: label,
                  uploadedDoc: uploaded,
                ),
              ],
            );
          }),
          const Gap(8),
        ],
      ),
    );
  }

  Widget _buildDocumentTile({
    required String type,
    required String label,
    Map<String, dynamic>? uploadedDoc,
  }) {
    final isUploading = _uploadingType == type;
    final status = uploadedDoc?['status'] as String?;
    final rejectionReason = uploadedDoc?['rejectionReason'] as String?;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (uploadedDoc == null) {
      statusColor = AppColors.textSecondary;
      statusText = 'Not Uploaded';
      statusIcon = Icons.cloud_upload_outlined;
    } else {
      switch (status) {
        case 'approved':
          statusColor = AppColors.success;
          statusText = 'Approved';
          statusIcon = Icons.check_circle;
          break;
        case 'pending':
        case 'under_review':
          statusColor = Colors.orange;
          statusText = status == 'under_review' ? 'Under Review' : 'Pending';
          statusIcon = Icons.hourglass_top;
          break;
        case 'rejected':
          statusColor = AppColors.warning;
          statusText = 'Rejected';
          statusIcon = Icons.cancel;
          break;
        case 'expired':
          statusColor = AppColors.error;
          statusText = 'Expired';
          statusIcon = Icons.timer_off;
          break;
        default:
          statusColor = AppColors.textSecondary;
          statusText = 'Unknown';
          statusIcon = Icons.help_outline;
      }
    }

    return InkWell(
      onTap: isUploading ? null : () => _onDocumentTap(type, label, uploadedDoc),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Corners.c8),
              ),
              child: isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Icon(statusIcon, color: statusColor, size: 20),
            ),
            const Gap(14),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.t1.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    statusText,
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                  if (status == 'rejected' && rejectionReason != null) ...[
                    const Gap(4),
                    Text(
                      'Reason: $rejectionReason',
                      style: TextStyles.t2.copyWith(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action icon
            if (!isUploading)
              Icon(
                uploadedDoc == null ||
                        status == 'rejected' ||
                        status == 'expired'
                    ? Icons.cloud_upload_outlined
                    : Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _onDocumentTap(
    String type,
    String label,
    Map<String, dynamic>? uploadedDoc,
  ) {
    final status = uploadedDoc?['status'] as String?;

    // Allow upload if not uploaded, rejected, or expired
    if (uploadedDoc == null || status == 'rejected' || status == 'expired') {
      _uploadDocument(type, label);
      return;
    }

    // Show details for uploaded documents
    _showDocumentDetails(label, uploadedDoc);
  }

  void _showDocumentDetails(String label, Map<String, dynamic> doc) {
    final status = doc['status'] as String? ?? 'unknown';
    final url = doc['url'] as String?;
    final uploadedAt = doc['uploadedAt'] as String?;
    final expiryDate = doc['expiryDate'] as String?;
    final reviewedAt = doc['reviewedAt'] as String?;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.c20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Text(
                label,
                style: TextStyles.t1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(16),

              if (url != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Corners.c8),
                  child: Image.network(
                    url,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: AppColors.textSecondary, size: 48),
                      ),
                    ),
                  ),
                ),
                const Gap(16),
              ],

              _buildDetailRow('Status', _formatStatus(status)),
              if (uploadedAt != null)
                _buildDetailRow('Uploaded', _formatDate(uploadedAt)),
              if (reviewedAt != null)
                _buildDetailRow('Reviewed', _formatDate(reviewedAt)),
              if (expiryDate != null)
                _buildDetailRow('Expires', _formatDate(expiryDate)),

              const Gap(16),

              // Re-upload button for approved docs
              if (status == 'approved')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final type = doc['type'] as String? ?? '';
                      _uploadDocument(type, label);
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Re-upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.t2.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyles.t1.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDocType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
