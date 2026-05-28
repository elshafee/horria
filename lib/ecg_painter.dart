import 'package:flutter/material.dart';

class EcgPainter extends CustomPainter {
  final List<double> dataPoints;
  final double gainScale;
  final double pixelsPerSample;
  final bool showGrid;

  EcgPainter({
    required this.dataPoints,
    this.gainScale = 150.0,
    this.pixelsPerSample = 1.2,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;

    if (showGrid) {
      _drawMedicalGrid(canvas, size);
    }

    if (dataPoints.isEmpty) return;

    final ecgPaint = Paint()
      ..color = const Color(0xFF00FF41) // Matrix/Medical Green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Draw from right to left: newest point at the right edge
    for (int i = dataPoints.length - 1; i >= 0; i--) {
      // Calculate x starting from the right edge
      double x = size.width - ((dataPoints.length - 1 - i) * pixelsPerSample);
      
      // Stop if we go off the left edge
      if (x < -10) break; 

      double y = midY - (dataPoints[i] * gainScale);

      if (i == dataPoints.length - 1) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, ecgPaint);
  }

  void _drawMedicalGrid(Canvas canvas, Size size) {
    final fineGridPaint = Paint()
      ..color = Colors.teal.withOpacity(0.1)
      ..strokeWidth = 0.5;

    final coarseGridPaint = Paint()
      ..color = Colors.teal.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const double gridSize = 10.0;
    const int majorStep = 5;

    for (double x = 0; x < size.width; x += gridSize) {
      int index = (x / gridSize).round();
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          (index % majorStep == 0) ? coarseGridPaint : fineGridPaint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      int index = (y / gridSize).round();
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          (index % majorStep == 0) ? coarseGridPaint : fineGridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) => true;
}
