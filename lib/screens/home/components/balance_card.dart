import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Eye Icon & Balance ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Visibility Button
              InkWell(
                onTap: () => setState(() => _isVisible = !_isVisible),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    _isVisible
                        ? Icons.remove_red_eye_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.primaryNavy,
                    size: 20,
                  ),
                ),
              ),

              // Balance Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isVisible ? "₹1,407" : "(¬_¬)", // The hidden face
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                      letterSpacing: _isVisible ? -1 : 2, // Space out the face
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Current Balance",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Graph Area ---
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: ChartPainter(isVisible: _isVisible)),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: 16),

          // --- Bottom Stats Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("INCOMING", "+₹15,237"),
              _buildStatItem("OUTGOING", "-₹1,50,237"),
              _buildStatItem("INVESTED", "₹1,407"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color labelColor = AppTheme.primaryNavy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isVisible ? value : "*****",
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// --- Custom Painter for the Smooth Green Graph ---
class ChartPainter extends CustomPainter {
  final bool isVisible;

  ChartPainter({required this.isVisible});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible) return; // Don't draw graph if hidden

    final paint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Hardcoded points to mimic the screenshot's shape
    // (Start Low -> Bump -> Low -> Bump -> Spike -> Low)
    final h = size.height;
    final w = size.width;

    path.moveTo(0, h * 0.9);
    path.quadraticBezierTo(w * 0.1, h * 0.9, w * 0.15, h * 0.7); // Small bump
    path.quadraticBezierTo(w * 0.2, h * 0.9, w * 0.3, h * 0.9); // Back down
    path.lineTo(w * 0.5, h * 0.9); // Flat
    path.quadraticBezierTo(w * 0.6, h * 0.9, w * 0.65, h * 0.75); // Small bump
    path.quadraticBezierTo(w * 0.7, h * 0.9, w * 0.75, h * 0.9); // Back down
    path.lineTo(w * 0.8, h * 0.9);
    path.lineTo(w * 0.82, h * 0.1); // THE BIG SPIKE (Net worth jump)
    path.lineTo(w * 0.84, h * 0.9); // Back down immediately
    path.quadraticBezierTo(w * 0.9, h * 0.7, w * 1.0, h * 0.8); // End curve

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw the Gradient Fill below the line
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = AppTheme.greenGraphGradient.createShader(
        Rect.fromLTWH(0, 0, w, h),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
