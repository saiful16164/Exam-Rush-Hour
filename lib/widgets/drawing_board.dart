
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingBoard extends StatefulWidget {
  final Widget child;
  final Function(Uint8List) onSave;
  final int initialRotation;

  const DrawingBoard({
    super.key,
    required this.child,
    required this.onSave,
    this.initialRotation = 0,
  });

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<DrawnPath> _paths = [];
  DrawnPath? _currentPath;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 4.0;
  late int _quarterTurns;
  bool _isZoomMode = false;
  final GlobalKey _globalKey = GlobalKey();
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _quarterTurns = widget.initialRotation;
  }

  void _onPanStart(DragStartDetails details) {
    if (_isZoomMode) return;
    setState(() {
      _currentPath = DrawnPath([details.localPosition], _currentColor, _currentStrokeWidth);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isZoomMode) return;
    setState(() {
      _currentPath?.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isZoomMode) return;
    if (_currentPath != null) {
      setState(() {
        _paths.add(_currentPath!);
        _currentPath = null;
      });
    }
  }

  Future<void> _saveDrawing() async {
    // Reset zoom before saving so the full image is captured
    final savedTransform = _transformController.value.clone();
    _transformController.value = Matrix4.identity();
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        widget.onSave(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint("Error saving drawing: $e");
    } finally {
      // Restore zoom
      _transformController.value = savedTransform;
    }
  }

  void _undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _paths.removeLast();
      });
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Draw / Zoom toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      icon: Icons.edit,
                      label: 'Draw',
                      isActive: !_isZoomMode,
                      onTap: () => setState(() => _isZoomMode = false),
                    ),
                    _buildModeButton(
                      icon: Icons.zoom_in,
                      label: 'Zoom',
                      isActive: _isZoomMode,
                      onTap: () => setState(() => _isZoomMode = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _paths.isNotEmpty ? _undo : null,
                tooltip: 'Undo',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.rotate_right),
                onPressed: () {
                  setState(() {
                    _quarterTurns = (_quarterTurns + 1) % 4;
                  });
                },
                tooltip: 'Rotate 90°',
              ),
              const SizedBox(width: 12),
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.green),
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.black),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Annotated View'),
                onPressed: _saveDrawing,
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformController,
            panEnabled: _isZoomMode,
            scaleEnabled: _isZoomMode,
            minScale: 0.5,
            maxScale: 5.0,
            child: RepaintBoundary(
              key: _globalKey,
              child: RotatedBox(
                quarterTurns: _quarterTurns,
                child: GestureDetector(
                  onPanStart: _isZoomMode ? null : _onPanStart,
                  onPanUpdate: _isZoomMode ? null : _onPanUpdate,
                  onPanEnd: _isZoomMode ? null : _onPanEnd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.child,
                      CustomPaint(
                        painter: DrawingPainter(_paths, _currentPath),
                        size: Size.infinite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.black : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _currentColor == color ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (_currentColor == color)
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)
          ],
        ),
      ),
    );
  }
}

class DrawnPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnPath(this.points, this.color, this.strokeWidth);
}

class DrawingPainter extends CustomPainter {
  final List<DrawnPath> paths;
  final DrawnPath? currentPath;

  DrawingPainter(this.paths, this.currentPath);

  @override
  void paint(Canvas canvas, Size size) {
    for (var path in paths) {
      _paintPath(canvas, path);
    }
    if (currentPath != null) {
      _paintPath(canvas, currentPath!);
    }
  }

  void _paintPath(Canvas canvas, DrawnPath path) {
    if (path.points.isEmpty) return;

    final paint = Paint()
      ..color = path.color
      ..strokeWidth = path.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p = Path();
    p.moveTo(path.points.first.dx, path.points.first.dy);
    for (int i = 1; i < path.points.length; i++) {
      p.lineTo(path.points[i].dx, path.points[i].dy);
    }
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
