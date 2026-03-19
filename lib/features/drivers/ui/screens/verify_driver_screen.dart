import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/features/drivers/ui/widgets/driver_app_drawer.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Main driver verification screen.
///
/// Calls `GET /users/driver-status` on load and renders:
/// • No application  → prompt to apply
/// • pending_verification / under_review → status tracker
/// • active → approved, navigate to driver home
/// • suspended / banned / deactivated → blocked message
class VerifyDriverScreen extends ConsumerStatefulWidget {
  const VerifyDriverScreen({super.key});

  @override
  ConsumerState<VerifyDriverScreen> createState() => _VerifyDriverScreenState();
}

class _VerifyDriverScreenState extends ConsumerState<VerifyDriverScreen> {
  bool _isLoading = true;
  String? _error;

  // Parsed from /users/driver-status response
  bool _hasApplication = false;
  String?
  _status; // pending_verification, under_review, active, suspended, banned, deactivated
  Map<String, dynamic>? _driverProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchStatus());
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(driverNotifierProvider.notifier).fetchApplicationStatus();

    if (!mounted) return;

    final appStatus = ref.read(driverNotifierProvider).applicationStatus;
    final errMsg = ref.read(driverNotifierProvider).errorMessage;

    if (appStatus != null) {
      setState(() {
        _hasApplication = appStatus['hasApplication'] as bool? ?? false;
        _status = appStatus['status'] as String?;
        _driverProfile = appStatus['driverProfile'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = errMsg ?? 'Failed to fetch driver status';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading:
            // IconButton(
            //   icon: const Icon(Icons.close, color: AppColors.textPrimary),
            //   onPressed: () => context.pop(),
            // ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: 24.0),
                color: AppColors.onAccent,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
        title: Text('Driver Verification', style: TextStyles.t1),
        centerTitle: true,
      ),
      drawer: const DriverAppDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _error != null
          ? _buildErrorView()
          : _hasApplication
          ? _buildStatusView()
          : _buildNoApplicationView(),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ERROR VIEW
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const Gap(24),
            Text(
              'Something went wrong',
              style: TextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyles.t2.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const Gap(24),
            CustomButton(text: 'Retry', onPressed: _fetchStatus),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NO APPLICATION — prompt user to apply
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildNoApplicationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Gap(32),

          // Illustration
          // Container(
          //   width: 160,
          //   height: 160,
          //   decoration: BoxDecoration(
          //     color: AppColors.accent.withValues(alpha: 0.08),
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(
          //     Icons.drive_eta_outlined,
          //     size: 72,
          //     color: AppColors.accent,
          //   ),
          // ),
          
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.accentLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Phone illustration
                  Container(
                    width: 100,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const Gap(12),
                        Container(
                          width: 60,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Gap(6),
                        Container(
                          width: 40,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checkmark badge
                  Positioned(
                    right: 40,
                    top: 50,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Gap(40),

          Text(
            'Become a Drup Driver',
            style: TextStyles.h1.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const Gap(12),

          Text(
            'Earn money by driving with Drup. Submit your\napplication and start your journey today.',
            textAlign: TextAlign.center,
            style: TextStyles.t2.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const Gap(40),

          // Benefits
          _benefitCard(
            icon: Icons.schedule,
            title: 'Flexible Schedule',
            description: 'Drive when you want, earn on your own terms.',
          ),
          const Gap(12),
          _benefitCard(
            icon: Icons.payments_outlined,
            title: 'Weekly Payouts',
            description: 'Get paid directly to your bank account every week.',
          ),
          const Gap(12),
          _benefitCard(
            icon: Icons.security_outlined,
            title: 'Safety First',
            description:
                'All rides are tracked and insured for your protection.',
          ),

          const Gap(40),

          CustomButton(
            text: 'Apply Now',
            onPressed: () async {
              final result = await context.push<bool>(
                AppRoutes.applyDriverRoute,
              );
              if (result == true && mounted) {
                _fetchStatus();
              }
            },
          ),

          const Gap(16),

          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Maybe later',
                style: TextStyles.t2.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const Gap(32),
        ],
      ),
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Corners.c8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.t1.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(2),
                Text(
                  description,
                  style: TextStyles.t2.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATUS VIEW — pending / under_review / active / suspended / banned
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildStatusView() {
    switch (_status) {
      case 'active':
        return _buildApprovedView();
      case 'suspended':
      case 'deactivated':
      case 'banned':
        return _buildBlockedView();
      case 'pending_verification':
      case 'under_review':
      default:
        return _buildPendingView();
    }
  }

  // ── Pending / Under Review ──

  Widget _buildPendingView() {
    final isUnderReview = _status == 'under_review';
    final vehicle = _driverProfile?['vehicle'] as Map<String, dynamic>?;
    final documents = _driverProfile?['documents'] as List<dynamic>? ?? [];
    final createdAt = _driverProfile?['createdAt'] as String?;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _fetchStatus,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Gap(16),

          // Status hero
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (isUnderReview ? AppColors.accent : AppColors.warning)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnderReview ? Icons.fact_check_outlined : Icons.hourglass_top,
                size: 56,
                color: isUnderReview ? AppColors.accent : AppColors.warning,
              ),
            ),
          ),

          const Gap(24),

          Text(
            isUnderReview
                ? 'Application Under Review'
                : 'Application Submitted',
            textAlign: TextAlign.center,
            style: TextStyles.h1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const Gap(8),

          Text(
            isUnderReview
                ? 'Our team is reviewing your documents.\nThis usually takes 1–2 business days.'
                : 'Your application is pending verification.\nPlease upload required documents to proceed.',
            textAlign: TextAlign.center,
            style: TextStyles.t2.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const Gap(32),

          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isUnderReview ? AppColors.accent : AppColors.warning)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Corners.c50),
              ),
              child: Text(
                _formatStatus(_status),
                style: TextStyles.t1.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUnderReview ? AppColors.accent : AppColors.warning,
                ),
              ),
            ),
          ),

          const Gap(32),

          // Progress tracker
          _card(
            icon: Icons.timeline,
            title: 'Application Progress',
            children: [
              _progressStep(
                label: 'Application Submitted',
                isCompleted: true,
                isActive: false,
              ),
              _progressConnector(isCompleted: isUnderReview),
              _progressStep(
                label: 'Documents Verification',
                isCompleted: isUnderReview,
                isActive: !isUnderReview,
              ),
              _progressConnector(isCompleted: false),
              _progressStep(
                label: 'Approved',
                isCompleted: false,
                isActive: false,
              ),
            ],
          ),

          const Gap(16),

          // Vehicle info
          if (vehicle != null) ...[
            _card(
              icon: Icons.directions_car,
              title: 'Vehicle',
              children: [
                _infoRow(
                  'Type',
                  _capitalize(vehicle['type'] as String? ?? '—'),
                ),
                _infoRow(
                  'Vehicle',
                  '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
                ),
                _infoRow('Year', '${vehicle['year'] ?? '—'}'),
                _infoRow('Color', vehicle['color'] as String? ?? '—'),
                _infoRow(
                  'License Plate',
                  vehicle['licensePlate'] as String? ?? '—',
                ),
                _infoRow(
                  'Verified',
                  (vehicle['isVerified'] as bool? ?? false) ? 'Yes' : 'No',
                ),
              ],
            ),
            const Gap(16),
          ],

          // Documents summary
          _card(
            icon: Icons.description_outlined,
            title: 'Documents',
            children: [
              if (documents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No documents uploaded yet.',
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...documents.map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            d.toString(),
                            style: TextStyles.t2.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          if (createdAt != null) ...[
            const Gap(16),
            Center(
              child: Text(
                'Applied on ${_formatDate(createdAt)}',
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],

          const Gap(32),

          // Refresh hint
          Center(
            child: TextButton.icon(
              icon: const Icon(
                Icons.refresh,
                size: 18,
                color: AppColors.accent,
              ),
              label: Text(
                'Pull down to refresh status',
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.accent,
                ),
              ),
              onPressed: _fetchStatus,
            ),
          ),

          const Gap(32),
        ],
      ),
    );
  }

  // ── Approved ──

  Widget _buildApprovedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const Gap(32),
            Text(
              'You\'re Approved!',
              style: TextStyles.h1.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(12),
            Text(
              'Your driver application has been approved.\nYou can now start accepting rides.',
              textAlign: TextAlign.center,
              style: TextStyles.t2.copyWith(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(40),
            CustomButton(
              text: 'Go to Driver Home',
              onPressed: () => context.go(AppRoutes.driverHomeRoute),
            ),
          ],
        ),
      ),
    );
  }

  // ── Blocked (suspended / banned / deactivated) ──

  Widget _buildBlockedView() {
    final isBanned = _status == 'banned';
    final color = isBanned ? AppColors.error : AppColors.warning;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBanned ? Icons.block : Icons.pause_circle_outline,
                size: 64,
                color: color,
              ),
            ),
            const Gap(32),
            Text(
              _status == 'banned'
                  ? 'Account Banned'
                  : _status == 'suspended'
                  ? 'Account Suspended'
                  : 'Account Deactivated',
              style: TextStyles.h1.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(12),
            Text(
              isBanned
                  ? 'Your driver account has been permanently banned.\nPlease contact support for more information.'
                  : 'Your driver account has been temporarily suspended.\nPlease contact support for assistance.',
              textAlign: TextAlign.center,
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(32),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Corners.c50),
                ),
                child: Text(
                  _formatStatus(_status),
                  style: TextStyles.t1.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ),
            const Gap(32),
            CustomButton(
              text: 'Contact Support',
              onPressed: () {
                // TODO: navigate to support screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support coming soon')),
                );
              },
            ),
            const Gap(16),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Go Back',
                style: TextStyles.t2.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SHARED HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _card({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
              Icon(icon, size: 20, color: AppColors.accent),
              const Gap(8),
              Text(
                title,
                style: TextStyles.t1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Divider(color: AppColors.divider),
          const Gap(8),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            style: TextStyles.t1.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStep({
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    final color = isCompleted
        ? AppColors.success
        : isActive
        ? AppColors.warning
        : AppColors.textLight;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isActive
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : isActive
              ? const Icon(Icons.more_horiz, size: 16, color: AppColors.warning)
              : null,
        ),
        const Gap(12),
        Text(
          label,
          style: TextStyles.t1.copyWith(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isCompleted || isActive
                ? AppColors.textPrimary
                : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _progressConnector({required bool isCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Container(
        width: 2,
        height: 28,
        color: isCompleted ? AppColors.success : AppColors.divider,
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
