import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:uuid/uuid.dart';

import '../../../theme.dart';

/// Bottom sheet that lists the UPI apps installed on the device and launches
/// the chosen one to complete the (already-recorded) payment.
///
/// This is the ONLY file that touches `upi_pay`, so swapping the launcher out
/// later stays a one-file change.
class UpiAppPickerSheet extends StatefulWidget {
  final String vpa;
  final String payeeName;
  final double amount;
  final String transactionNote;

  const UpiAppPickerSheet({
    super.key,
    required this.vpa,
    required this.payeeName,
    required this.amount,
    required this.transactionNote,
  });

  @override
  State<UpiAppPickerSheet> createState() => _UpiAppPickerSheetState();
}

class _UpiAppPickerSheetState extends State<UpiAppPickerSheet> {
  static const _uuid = Uuid();
  final UpiPay _upiPay = UpiPay();

  late final Future<List<ApplicationMeta>> _apps =
      _upiPay.getInstalledUpiApplications();

  Future<void> _pay(ApplicationMeta app) async {
    try {
      await _upiPay.initiateTransaction(
        app: app.upiApplication,
        receiverUpiAddress: widget.vpa,
        receiverName: widget.payeeName,
        transactionRef: _uuid.v4(),
        amount: widget.amount.toStringAsFixed(2),
        transactionNote: widget.transactionNote,
      );
    } catch (_) {
      // The payment lives in the external app; we're only tracking. If the
      // launch fails we silently close — the expense is already saved.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pay ₹${widget.amount.toStringAsFixed(2)} with',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ApplicationMeta>>(
              future: _apps,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final apps = snapshot.data ?? const [];
                if (apps.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No UPI apps found on this device. Your expense has '
                      'been saved.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  children: apps.map(_appTile).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _appTile(ApplicationMeta app) {
    return InkWell(
      onTap: () => _pay(app),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          app.iconImage(44),
          const SizedBox(height: 6),
          Text(
            app.upiApplication.getAppName(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
