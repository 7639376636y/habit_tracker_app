import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final data = provider.dailyProgressData;
        final maxValue = data.isEmpty
            ? 100.0
            : data.reduce((a, b) => a > b ? a : b);
        final chartMax = maxValue < 20 ? 20.0 : maxValue + 5;

        return Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y-axis labels
                    SizedBox(
                      width: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${chartMax.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            '${(chartMax * 0.75).toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            '${(chartMax * 0.5).toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            '${(chartMax * 0.25).toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const Text('0%', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chart area
                    Expanded(
                      child: CustomPaint(
                        painter: _LineChartPainter(data, chartMax),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // X-axis labels
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(data.length > 10 ? 10 : data.length, (
                    index,
                  ) {
                    final dayIndex = (data.length / 10 * index).floor();
                    return Text(
                      '${dayIndex + 1}',
                      style: const TextStyle(fontSize: 9),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  _LineChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height - (size.height / 4 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw area fill
    final areaPath = Path();
    final linePath = Path();

    for (var i = 0; i < data.length; i++) {
      final x = size.width / (data.length - 1) * i;
      final y = size.height - (data[i] / maxValue * size.height);

      if (i == 0) {
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        areaPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Fill area
    final areaPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    // Draw line
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final x = size.width / (data.length - 1) * i;
      final y = size.height - (data[i] / maxValue * size.height);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
