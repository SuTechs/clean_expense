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
    final size = MediaQuery.sizeOf(context);
    final cutout = size.width * 0.7;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: cutout,
      height: cutout,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Scan & Pay'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final on = state.torchState == TorchState.on;
              final available = state.torchState != TorchState.unavailable;
              return IconButton(
                tooltip: 'Flash',
                icon: Icon(on ? Icons.flash_on_rounded : Icons.flash_off_rounded),
                color: on ? AppTheme.primaryGreen : Colors.white,
                onPressed: available ? () => _controller.toggleTorch() : null,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed camera preview.
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
            scanWindow: scanRect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),

          // Dimmed overlay with a clear, rounded cutout in the center.
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScannerOverlayPainter(
                cutout: scanRect,
                radius: 24,
                borderColor: _hint != null ? AppTheme.dangerRed : Colors.white,
              ),
            ),
          ),

          // Hint / instruction text below the cutout.
          Positioned(
            top: scanRect.bottom + 28,
            left: 32,
            right: 32,
            child: Text(
              _hint ?? 'Align the UPI QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hint != null ? AppTheme.dangerRed : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a translucent scrim over the whole screen, punches out a rounded
/// square for the scan window, and draws white corner brackets around it.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect cutout;
  final double radius;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.cutout,
    required this.radius,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(cutout, Radius.circular(radius));

    // Scrim everywhere except the cutout.
    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Thin frame border.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Corner brackets.
    final bracket = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final r = radius;

    void corner(Offset c, double dx, double dy) {
      final path = Path()
        ..moveTo(c.dx, c.dy + dy * (len))
        ..lineTo(c.dx, c.dy + dy * r)
        ..arcToPoint(
          Offset(c.dx + dx * r, c.dy),
          radius: Radius.circular(r),
          clockwise: dx == dy,
        )
        ..lineTo(c.dx + dx * len, c.dy);
      canvas.drawPath(path, bracket);
    }

    corner(cutout.topLeft, 1, 1);
    corner(cutout.topRight, -1, 1);
    corner(cutout.bottomLeft, 1, -1);
    corner(cutout.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.cutout != cutout || old.borderColor != borderColor;
}

/// Friendly fallback shown when the camera can't start (e.g. permission denied).
class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
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
