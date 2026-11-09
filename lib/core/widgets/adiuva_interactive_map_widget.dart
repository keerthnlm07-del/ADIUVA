import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/adiuva_colors.dart';

/// Interactive Map Widget for ADIUVA Location & Navigation
/// Supports pan, zoom, recenter, user position marker, and destination pin.
class AdiuvaInteractiveMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String address;
  final VoidCallback? onRecenter;
  final double height;

  const AdiuvaInteractiveMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.onRecenter,
    this.height = 240.0,
  });

  @override
  State<AdiuvaInteractiveMapWidget> createState() => _AdiuvaInteractiveMapWidgetState();
}

class _AdiuvaInteractiveMapWidgetState extends State<AdiuvaInteractiveMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Offset _panOffset = Offset.zero;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _recenter() {
    setState(() {
      _panOffset = Offset.zero;
      _zoomScale = 1.0;
    });
    widget.onRecenter?.call();
  }

  void _zoomIn() {
    setState(() {
      _zoomScale = math.min(_zoomScale + 0.25, 2.5);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = math.max(_zoomScale - 0.25, 0.6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.latitude != null && widget.longitude != null;

    return Semantics(
      label: 'Interactive Location Map View',
      child: Container(
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Dark sleek map background
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AdiuvaColors.primaryTeal.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Interactive Pan & Zoom Canvas
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _panOffset += details.delta;
                });
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _MapCanvasPainter(
                      panOffset: _panOffset,
                      zoomScale: _zoomScale,
                      pulseScale: _pulseAnimation.value,
                      hasLocation: hasLocation,
                      isDarkMode: true,
                    ),
                  );
                },
              ),
            ),

            // Map Overlay Badge: Lat/Lng & Address
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: AdiuvaColors.primaryTeal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasLocation
                                ? 'Lat: ${widget.latitude!.toStringAsFixed(4)}°, Lng: ${widget.longitude!.toStringAsFixed(4)}°'
                                : 'Locating GPS Signal...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zoom & Recenter Controls Stacked Right
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recenter Button
                  FloatingActionButton.small(
                    heroTag: 'map_recenter_btn',
                    onPressed: _recenter,
                    backgroundColor: AdiuvaColors.primaryTeal,
                    foregroundColor: Colors.white,
                    tooltip: 'Recenter on My Location',
                    child: const Icon(Icons.gps_fixed_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),
                  // Zoom In
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_in_btn',
                    onPressed: _zoomIn,
                    backgroundColor: AdiuvaColors.slate800,
                    foregroundColor: Colors.white,
                    tooltip: 'Zoom In',
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                  const SizedBox(height: 6),
                  // Zoom Out
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_out_btn',
                    onPressed: _zoomOut,
                    backgroundColor: AdiuvaColors.slate800,
                    foregroundColor: Colors.white,
                    tooltip: 'Zoom Out',
                    child: const Icon(Icons.remove_rounded, size: 20),
                  ),
                ],
              ),
            ),

            // Pan reset indicator if panned
            if (_panOffset != Offset.zero)
              Positioned(
                bottom: 12,
                left: 12,
                child: InkWell(
                  onTap: _recenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdiuvaColors.primaryTeal),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.center_focus_strong_rounded, color: AdiuvaColors.primaryTeal, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Reset View',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final Offset panOffset;
  final double zoomScale;
  final double pulseScale;
  final bool hasLocation;
  final bool isDarkMode;

  _MapCanvasPainter({
    required this.panOffset,
    required this.zoomScale,
    required this.pulseScale,
    required this.hasLocation,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final targetCenter = center + panOffset;

    // 1. Draw Grid Roads & Land Outlines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.6)
      ..strokeWidth = 6.0 * zoomScale;

    final mainRoadPaint = Paint()
      ..color = AdiuvaColors.primaryTeal.withValues(alpha: 0.25)
      ..strokeWidth = 10.0 * zoomScale;

    final step = 40.0 * zoomScale;

    // Draw background grid lines
    for (double x = (targetCenter.dx % step) - step; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = (targetCenter.dy % step) - step; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw stylized road networks relative to center
    canvas.drawLine(
      Offset(0, targetCenter.dy),
      Offset(size.width, targetCenter.dy),
      mainRoadPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx, 0),
      Offset(targetCenter.dx, size.height),
      mainRoadPaint,
    );

    canvas.drawLine(
      Offset(targetCenter.dx - 120 * zoomScale, targetCenter.dy - 100 * zoomScale),
      Offset(targetCenter.dx + 150 * zoomScale, targetCenter.dy + 120 * zoomScale),
      roadPaint,
    );

    canvas.drawLine(
      Offset(targetCenter.dx - 150 * zoomScale, targetCenter.dy + 80 * zoomScale),
      Offset(targetCenter.dx + 120 * zoomScale, targetCenter.dy - 110 * zoomScale),
      roadPaint,
    );

    if (!hasLocation) return;

    // 2. Pulsating Radar Halo around User Location
    final haloPaint = Paint()
      ..color = AdiuvaColors.primaryTeal.withValues(alpha: math.max(0.1, 0.4 - (pulseScale - 0.8) * 0.3))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 28 * pulseScale * zoomScale, haloPaint);

    // 3. User Location Outer Circle
    final outerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 10 * zoomScale, outerCirclePaint);

    // 4. User Location Core Dot (Bright Blue/Teal)
    final coreDotPaint = Paint()
      ..color = AdiuvaColors.primaryTeal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 7 * zoomScale, coreDotPaint);

    // 5. Compass direction indicator arrow
    final arrowPath = Path()
      ..moveTo(targetCenter.dx, targetCenter.dy - 16 * zoomScale)
      ..lineTo(targetCenter.dx - 5 * zoomScale, targetCenter.dy - 8 * zoomScale)
      ..lineTo(targetCenter.dx + 5 * zoomScale, targetCenter.dy - 8 * zoomScale)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.hasLocation != hasLocation;
  }
}
