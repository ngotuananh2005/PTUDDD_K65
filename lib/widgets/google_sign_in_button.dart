import 'package:flutter/material.dart';

/// Nút bấm Đăng nhập bằng Google chuẩn giao diện Material 3 & Google Branding
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Đăng nhập bằng Google',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF131314) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
        side: BorderSide(
          color: isDark ? const Color(0xFF8E918F) : const Color(0xFF747775),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Biểu tượng Google Logo (Custom vector paint)
                const _GoogleIcon(size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Widget vẽ biểu tượng 4 màu chuẩn của Google
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Tỉ lệ chuẩn 4 màu Google: Xanh dương, Xanh lá, Vàng, Đỏ
    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintGreen = Paint()..color = const Color(0xFF34A853);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintRed = Paint()..color = const Color(0xFFEA4335);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Đường vòng ngoài
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Vẽ cung Đỏ (Góc trên)
    canvas.drawArc(rect, -0.785, -2.356, true, paintRed);
    // Vẽ cung Vàng (Góc trái)
    canvas.drawArc(rect, -3.1415, -1.57, true, paintYellow);
    // Vẽ cung Xanh lá (Góc dưới)
    canvas.drawArc(rect, -4.712, -1.57, true, paintGreen);
    // Vẽ cung Xanh dương (Góc phải)
    canvas.drawArc(rect, 0.0, -0.785, true, paintBlue);

    // Khoét tâm màu trắng/nền để tạo hình chữ G
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, innerPaint);

    // Thanh ngang chữ G
    final barRect = Rect.fromLTRB(center.dx - 1, center.dy - (radius * 0.2), w, center.dy + (radius * 0.2));
    canvas.drawRect(barRect, paintBlue);

    // Cắt góc phần tư trên bên phải
    final cutRect = Rect.fromLTRB(center.dx, 0, w, center.dy - (radius * 0.2));
    canvas.drawRect(cutRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
