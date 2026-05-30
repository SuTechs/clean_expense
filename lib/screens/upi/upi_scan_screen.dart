import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/utils/upi_uri.dart';
import '../../theme.dart';
import 'upi_payment_screen.dart';

/// Full-screen camera view that scans a UPI QR code.
///
/// On the first valid UPI QR detected, it parses the payee details and pushes
/// [UpiPaymentScreen]. Non-UPI / malformed QRs surface an inline hint and the
/// scanner keeps running so the user can try again.
class UpiScanScreen extends StatefulWidget {
  const UpiScanScreen({super.key});

  @override
  State<UpiScanScreen> createState() => _UpiScanScreenState();
}

class _UpiScanScreenState extends State<UpiScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Guards against handling more than one detection while we navigate away.
  bool _handled = false;
  String? _hint;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);

    final data = UpiQrData.tryParse(raw);
    if (data == null) {
      // Not a UPI QR — nudge the user and keep scanning.
      if (mounted && _hint == null) {
        setState(() => _hint = "That doesn't look like a UPI QR. Try another.");
      }
      return;
    }

    _handled = true;
    HapticFeedback.mediumImpact();
    await _controller.stop();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UpiPaymentScreen(qr: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan UPI QR'),
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),

          // Scan window overlay.
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          // Hint / instruction text.
          Positioned(
            bottom: 64,
            left: 32,
            right: 32,
            child: Text(
              _hint ?? 'Point your camera at a UPI QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hint != null ? AppTheme.dangerRed : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly fallback shown when the camera can't start (e.g. permission denied).
class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'Camera permission is required to scan UPI QR codes. Enable it in Settings and try again.'
                : 'Unable to start the camera. Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
