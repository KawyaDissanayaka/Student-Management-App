import 'dart:math';
import 'package:flutter/material.dart';

/// A pure Flutter CustomPainter-based QR-style Code Display
/// with position markers, alignment patterns, dynamic pseudo-matrix generation,
/// and center university emblem/icon.
class DynamicQrView extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const DynamicQrView({
    super.key,
    required this.data,
    this.size = 240,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withAlpha(50),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
        painter: _QrPainter(
          data: data,
          fgColor: foregroundColor,
          bgColor: backgroundColor,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  final Color fgColor;
  final Color bgColor;

  _QrPainter({
    required this.data,
    required this.fgColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.fill;

    const int matrixSize = 25; // 25x25 grid
    final double cellSize = size.width / matrixSize;

    // Deterministic pseudo-random seed from data string
    int hash = 5381;
    for (int i = 0; i < data.length; i++) {
      hash = ((hash << 5) + hash) + data.codeUnitAt(i);
    }
    final rand = Random(hash.abs());

    // Generate grid matrix
    final List<List<bool>> matrix = List.generate(
      matrixSize,
      (_) => List.generate(matrixSize, (_) => rand.nextBool()),
    );

    // 1. Draw Corner Position Detection Patterns (Top-Left, Top-Right, Bottom-Left)
    _drawPositionPattern(matrix, 0, 0);
    _drawPositionPattern(matrix, 0, matrixSize - 7);
    _drawPositionPattern(matrix, matrixSize - 7, 0);

    // 2. Draw Alignment Pattern (Bottom-Right area)
    _drawAlignmentPattern(matrix, matrixSize - 9, matrixSize - 9);

    // 3. Clear Center area for logo/emblem
    const int centerStart = 9;
    const int centerEnd = 15;
    for (int r = centerStart; r <= centerEnd; r++) {
      for (int c = centerStart; c <= centerEnd; c++) {
        matrix[r][c] = false;
      }
    }

    // 4. Render matrix dots on canvas
    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        if (matrix[r][c]) {
          final rect = Rect.fromLTWH(
            c * cellSize + 0.5,
            r * cellSize + 0.5,
            cellSize - 1.0,
            cellSize - 1.0,
          );
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), fgPaint);
        }
      }
    }

    // 5. Draw Center Badge / Icon Box
    final centerRect = Rect.fromLTWH(
      centerStart * cellSize,
      centerStart * cellSize,
      (centerEnd - centerStart + 1) * cellSize,
      (centerEnd - centerStart + 1) * cellSize,
    );

    final badgePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final badgeBorder = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(RRect.fromRectAndRadius(centerRect, const Radius.circular(6)), badgePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(centerRect, const Radius.circular(6)), badgeBorder);

    // Draw little graduation cap / lock icon representation in center
    final iconPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;

    final cx = centerRect.center.dx;
    final cy = centerRect.center.dy;
    final path = Path()
      ..moveTo(cx, cy - 8)
      ..lineTo(cx + 10, cy - 3)
      ..lineTo(cx, cy + 2)
      ..lineTo(cx - 10, cy - 3)
      ..close();
    canvas.drawPath(path, iconPaint);

    final capUnder = Path()
      ..moveTo(cx - 6, cy)
      ..lineTo(cx - 6, cy + 5)
      ..arcToPoint(Offset(cx + 6, cy + 5), radius: const Radius.circular(6))
      ..lineTo(cx + 6, cy)
      ..close();
    canvas.drawPath(capUnder, iconPaint);
  }

  void _drawPositionPattern(List<List<bool>> matrix, int top, int left) {
    // 7x7 outer box
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        if (r == 0 || r == 6 || c == 0 || c == 6) {
          matrix[top + r][left + c] = true;
        } else if (r >= 2 && r <= 4 && c >= 2 && c <= 4) {
          matrix[top + r][left + c] = true;
        } else {
          matrix[top + r][left + c] = false;
        }
      }
    }
    // 1-cell separator around pattern
    for (int r = -1; r <= 7; r++) {
      for (int c = -1; c <= 7; c++) {
        final pr = top + r;
        final pc = left + c;
        if (pr >= 0 && pr < matrix.length && pc >= 0 && pc < matrix.length) {
          if (r == -1 || r == 7 || c == -1 || c == 7) {
            matrix[pr][pc] = false;
          }
        }
      }
    }
  }

  void _drawAlignmentPattern(List<List<bool>> matrix, int top, int left) {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (r == 0 || r == 4 || c == 0 || c == 4 || (r == 2 && c == 2)) {
          matrix[top + r][left + c] = true;
        } else {
          matrix[top + r][left + c] = false;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.fgColor != fgColor;
  }
}
