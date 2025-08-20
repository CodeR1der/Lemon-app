// qr_generator_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatelessWidget {
  final String companyId;

  QRGeneratorScreen({
    required this.companyId,
  });

  String _generateQRData() {
    // Просто передаем ID компании
    final data = {
      'companyId': companyId,
      'type': 'company_join',
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-код компании'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _generateQRData(),
                        size: 250,
                        backgroundColor: Colors.white,
                        embeddedImage: const AssetImage('assets/lemon_app_logo_icon_bg.webp'), // Лого с белым фоном
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size.square(35), // 25-30% от размера QR
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ID: $companyId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Попросите пользователя отсканировать этот код для присоединения к компании',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}