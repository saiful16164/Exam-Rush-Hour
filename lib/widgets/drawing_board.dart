import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingBoard extends StatefulWidget {
  final Widget child;
  final Function(Uint8List) onSave;

  const DrawingBoard({
    super.key,
    required this.child,
    required this.onSave,
  });

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<DrawnPath> _paths = [];
  DrawnPath? _currentPath;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 4.0;
  final GlobalKey _globalKey = GlobalKey();

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPath = DrawnPath([details.localPosition], _currentColor, _currentStrokeWidth);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPath?.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null) {
      setState(() {
        _paths.add(_currentPath!);
        _currentPath = null;
      });
    }
  }

  Future<void> _saveDrawing() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        widget.onSave(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint("Error saving drawing: $e");
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _paths.isNotEmpty ? _undo : null,
                tooltip: 'Undo',
              ),
              const SizedBox(width: 16),
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
          child: RepaintBoundary(
            key: _globalKey,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
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
      ],
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
