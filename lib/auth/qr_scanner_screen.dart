// qr_scanner_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  bool isTorchOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование QR кода'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isTorchOn = !isTorchOn;
              });
              controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!isScanning) return;

              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? '';
                _processScannedData(code);
              }
            },
          ),

          // Overlay с рамкой для сканирования
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Наведите камеру на QR код компании',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processScannedData(String rawData) {
    try {
      if (rawData.contains('companyId') || rawData.startsWith('{')) {
        final jsonData = jsonDecode(rawData);

        // Проверяем наличие companyId и что он не null
        if (jsonData.containsKey('companyId') && jsonData['companyId'] != null) {
          final companyId = jsonData['companyId'].toString();

          setState(() => isScanning = false);
          Navigator.pop(context, companyId);
        } else {
          // Если companyId нет или он null
          setState(() => isScanning = false);
          Navigator.pop(context, null);
        }
      } else {
        // Если это не JSON с companyId
        setState(() => isScanning = false);
        Navigator.pop(context, null);
      }
    } catch (e) {
      print('Error processing QR: $e');
      setState(() => isScanning = false);
      Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Кастомный оверлей для сканера
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaSize = 250.0;

    // Рисуем затемнение вокруг
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);

    // Вырезаем область сканирования
    final scanRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final clipPaint = Paint()..blendMode = BlendMode.clear;

    //canvas.drawRect(scanRect, clipPaint);

    // Рамка сканера
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(scanRect, borderPaint);

    // Уголки
    final cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Левый верхний
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Правый верхний
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right - cornerLength, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Левый нижний
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      cornerPaint,
    );

    // Правый нижний
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom),
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
