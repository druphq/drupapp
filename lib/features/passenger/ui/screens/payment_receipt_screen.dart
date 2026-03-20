import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// A printable / shareable receipt view for a single payment.
class PaymentReceiptScreen extends StatelessWidget {
  const PaymentReceiptScreen({super.key, required this.payment});
  final PaymentHistoryItem payment;

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return AppColors.green400;
      case 'failed' || 'cancelled':
        return AppColors.red400;
      case 'pending':
        return AppColors.orange400;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return AppColors.green50;
      case 'failed' || 'cancelled':
        return AppColors.red50;
      case 'pending':
        return AppColors.orange50;
      default:
        return AppColors.grey50;
    }
  }

  // PDF status colour helpers (same logic, PdfColor output)
  static PdfColor _pdfStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return const PdfColor.fromInt(0xFF4CAF50);
      case 'failed' || 'cancelled':
        return const PdfColor.fromInt(0xFFF44336);
      case 'pending':
        return const PdfColor.fromInt(0xFFFFA500);
      default:
        return const PdfColor.fromInt(0xFF757575);
    }
  }

  static PdfColor _pdfStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return const PdfColor.fromInt(0xFFE8F5E9);
      case 'failed' || 'cancelled':
        return const PdfColor.fromInt(0xFFFFB2B2);
      case 'pending':
        return const PdfColor.fromInt(0xFFFFF3E0);
      default:
        return const PdfColor.fromInt(0xFFF4F4F6);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pickupName = payment.entityId?.pickup?.name ?? '';
    final dropoffName = payment.entityId?.dropoff?.name ?? '';
    final rideNumber = payment.entityId?.rideNumber ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Receipt',
          style: TextStyles.t1.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.onAccent,
            ),
            tooltip: 'Save as PDF',
            onPressed: () => _savePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.onAccent),
            tooltip: 'Share receipt',
            onPressed: () {
              _shareReceipt(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Receipt card ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Corners.c20),
            ),
            child: Column(
              children: [
                // ── Brand header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(Corners.c20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 36,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const Gap(8),
                      Text(
                        'DRUP',
                        style: TextStyles.t1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Payment Receipt',
                        style: TextStyles.t2.copyWith(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Amount section ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyles.t2.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '₦${formatThousand(payment.amount)}',
                        style: TextStyles.t1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(10),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(payment.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment.status.capitalizeFirstChar(),
                          style: TextStyles.t2.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(payment.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _divider(),

                // ── Trip details section ──
                if (pickupName.isNotEmptyOrNull ||
                    dropoffName.isNotEmptyOrNull) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Trip Details',
                        style: TextStyles.t1.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRoutePreview(pickupName, dropoffName),
                  ),
                  if (rideNumber.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _detailRow('Ride Number', rideNumber),
                    ),
                  const Gap(16),
                  _divider(),
                ],

                // ── Payment details section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Details',
                        style: TextStyles.t1.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(14),
                      _detailRow(
                        'Payment Type',
                        _formatType(payment.paymentType),
                      ),
                      const Gap(10),
                      _detailRow(
                        'Payment Method',
                        payment.paymentMethod.capitalizeFirstChar(),
                      ),
                      const Gap(10),
                      _detailRow('Currency', payment.currency.toUpperCase()),
                      const Gap(10),
                      _detailRow('Date', formatDateTime(payment.createdAt)),
                    ],
                  ),
                ),

                _divider(),

                // ── Reference section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference',
                        style: TextStyles.t1.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: payment.reference),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reference copied to clipboard'),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(Corners.c8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  payment.reference,
                                  style: TextStyles.t2.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Gap(8),
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Footer ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(Corners.c20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Thank you for riding with DRUP',
                        style: TextStyles.t2.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'support@drupapp.com',
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Save as PDF button ──
          const Gap(16),
          Builder(
            builder: (ctx) => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Corners.c10),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  'Save as PDF',
                  style: TextStyles.btnStyle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onPressed: () => _savePdf(ctx),
              ),
            ),
          ),
          const Gap(24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _divider() {
    return Row(
      children: List.generate(
        40,
        (i) => Expanded(
          child: Container(
            height: 1,
            color: i.isEven ? AppColors.divider : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePreview(String pickupName, String dropoffName) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                height: 14,
                width: 14,
                decoration: const BoxDecoration(
                  color: AppColors.pickupMarker,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.circle, color: Colors.white, size: 6),
              ),
              Expanded(child: Container(width: 2, color: AppColors.divider)),
              const Icon(Icons.location_on, size: 18, color: AppColors.red400),
            ],
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickupName.isNotEmpty ? pickupName : 'Pickup',
                  style: TextStyles.t2.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(12),
                Text(
                  dropoffName.isNotEmpty ? dropoffName : 'Dropoff',
                  style: TextStyles.t2.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.capitalizeFirstChar())
        .join(' ');
  }

  void _shareReceipt(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('DRUP Payment Receipt');
    buffer.writeln('========================');
    buffer.writeln('Amount: ₦${formatThousand(payment.amount)}');
    buffer.writeln('Status: ${payment.status.capitalizeFirstChar()}');
    buffer.writeln('Date: ${formatDateTime(payment.createdAt)}');
    buffer.writeln('Payment: ${payment.paymentMethod.capitalizeFirstChar()}');
    buffer.writeln('Reference: ${payment.reference}');

    if (payment.entityId?.rideNumber != null) {
      buffer.writeln('Ride: ${payment.entityId!.rideNumber}');
    }
    if (payment.entityId?.pickup?.name != null) {
      buffer.writeln('From: ${payment.entityId!.pickup!.name}');
    }
    if (payment.entityId?.dropoff?.name != null) {
      buffer.writeln('To: ${payment.entityId!.dropoff!.name}');
    }
    buffer.writeln('========================');
    buffer.writeln('Thank you for riding with DRUP');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt copied to clipboard')),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF generation
  // ---------------------------------------------------------------------------

  Future<void> _savePdf(BuildContext context) async {
    final pdfBytes = await _generatePdf();
    if (!context.mounted) return;

    // Opens native share / save / print dialog
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'DRUP_Receipt_${payment.reference}',
    );
  }

  Future<Uint8List> _generatePdf() async {
    final doc = pw.Document(title: 'DRUP Receipt', author: 'DRUP');

    // Colours
    const accent = PdfColor.fromInt(0xFF222D65);
    const grey = PdfColor.fromInt(0xFF757575);
    const dividerC = PdfColor.fromInt(0xFFE0E0E0);
    const black = PdfColor.fromInt(0xFF000000);
    const surfaceC = PdfColor.fromInt(0xFFF0F0F0);
    const pickup = PdfColor.fromInt(0xFF4CAF50);
    const dropoff = PdfColor.fromInt(0xFFF44336);

    final pickupName = payment.entityId?.pickup?.name ?? '';
    final dropoffName = payment.entityId?.dropoff?.name ?? '';
    final rideNumber = payment.entityId?.rideNumber ?? '';
    final hasTrip = pickupName.isNotEmpty || dropoffName.isNotEmpty;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            children: [
              // ── Brand header ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: const pw.BoxDecoration(
                  color: accent,
                  borderRadius: pw.BorderRadius.vertical(
                    top: pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'DRUP',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 3,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Payment Receipt',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromInt(0xCCFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),

              // ── White body ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: dividerC, width: 0.5),
                  borderRadius: const pw.BorderRadius.vertical(
                    bottom: pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Amount
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Total Amount',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: grey,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            '\u20A6${formatThousand(payment.amount)}',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: black,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          // Status badge
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: _pdfStatusBg(payment.status),
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Text(
                              payment.status.capitalizeFirstChar(),
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: _pdfStatusColor(payment.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 20),
                    _pdfDashedDivider(dividerC),
                    pw.SizedBox(height: 16),

                    // Trip details
                    if (hasTrip) ...[
                      pw.Text(
                        'Trip Details',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: grey,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Pickup
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 10,
                            height: 10,
                            margin: const pw.EdgeInsets.only(top: 2, right: 8),
                            decoration: const pw.BoxDecoration(
                              color: pickup,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              pickupName.isNotEmpty ? pickupName : 'Pickup',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 4),
                        height: 14,
                        width: 2,
                        color: dividerC,
                      ),
                      // Dropoff
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 10,
                            height: 10,
                            margin: const pw.EdgeInsets.only(top: 2, right: 8),
                            decoration: const pw.BoxDecoration(
                              color: dropoff,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              dropoffName.isNotEmpty ? dropoffName : 'Dropoff',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      if (rideNumber.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        _pdfDetailRow('Ride Number', rideNumber, grey, black),
                      ],
                      pw.SizedBox(height: 16),
                      _pdfDashedDivider(dividerC),
                      pw.SizedBox(height: 16),
                    ],

                    // Payment details
                    pw.Text(
                      'Payment Details',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: grey,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _pdfDetailRow(
                      'Payment Type',
                      _formatType(payment.paymentType),
                      grey,
                      black,
                    ),
                    pw.SizedBox(height: 6),
                    _pdfDetailRow(
                      'Payment Method',
                      payment.paymentMethod.capitalizeFirstChar(),
                      grey,
                      black,
                    ),
                    pw.SizedBox(height: 6),
                    _pdfDetailRow(
                      'Currency',
                      payment.currency.toUpperCase(),
                      grey,
                      black,
                    ),
                    pw.SizedBox(height: 6),
                    _pdfDetailRow(
                      'Date',
                      formatDateTime(payment.createdAt),
                      grey,
                      black,
                    ),

                    pw.SizedBox(height: 16),
                    _pdfDashedDivider(dividerC),
                    pw.SizedBox(height: 16),

                    // Reference
                    pw.Text(
                      'Reference',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: grey,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        color: surfaceC,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        payment.reference,
                        style: const pw.TextStyle(fontSize: 10, color: black),
                      ),
                    ),

                    pw.SizedBox(height: 24),

                    // Footer
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Thank you for riding with DRUP',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: grey,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'support@drupapp.com',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ── PDF helper widgets ──

  static pw.Widget _pdfDashedDivider(PdfColor color) {
    return pw.Row(
      children: List.generate(
        60,
        (i) => pw.Expanded(
          child: pw.Container(
            height: 1,
            color: i.isEven ? color : PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _pdfDetailRow(
    String label,
    String value,
    PdfColor labelColor,
    PdfColor valueColor,
  ) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, color: labelColor),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
}
