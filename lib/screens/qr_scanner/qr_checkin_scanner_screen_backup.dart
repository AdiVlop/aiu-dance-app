import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart'; // Temporar dezactivat pentru APK minimal
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aiu_dance/services/qr_attendance_service.dart';
import 'package:aiu_dance/utils/logger.dart';

class QRCheckinScannerScreen extends StatefulWidget {
  const QRCheckinScannerScreen({super.key});

  @override
  State<QRCheckinScannerScreen> createState() => _QRCheckinScannerScreenState();
}

class _QRCheckinScannerScreenState extends State<QRCheckinScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _lastScannedCode;
  Map<String, dynamic>? _scanResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String? _getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing || _hasScanned || qrData == _lastScannedCode) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = qrData;
    });

    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        _showErrorResult('Utilizator neautentificat. Te rog să te conectezi din nou.');
        return;
      }

      Logger.info('Processing QR scan for user: $userId');
      Logger.info('QR data: $qrData');

      final result = await QRAttendanceService.processQRScan(
        qrData: qrData,
        userId: userId,
      );

      setState(() {
        _scanResult = result;
        _hasScanned = true;
        _isProcessing = false;
      });

      if (result['success'] == true) {
        _showSuccessResult(result);
      } else {
        _showErrorResult(result['message'] ?? 'Eroare necunoscută');
      }

    } catch (e) {
      Logger.error('Error processing QR code: $e');
      setState(() {
        _isProcessing = false;
      });
      _showErrorResult('Eroare la procesarea codului QR: ${e.toString()}');
    }
  }

  void _showSuccessResult(Map<String, dynamic> result) {
    final data = result['data'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Prezență Înregistrată!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? 'Prezența a fost înregistrată cu succes.',
              style: const TextStyle(fontSize: 16),
            ),
            if (data != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['course_title'] != null) ...[
                      const Text(
                        'Curs:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        data['course_title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (data['recorded_at'] != null) ...[
                      const Text(
                        'Înregistrat la:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatDateTime(data['recorded_at']),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Înapoi la ecranul anterior
            },
            child: const Text('Închide'),
          ),
          ElevatedButton(
            onPressed: _resetScanner,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Scanează din nou'),
          ),
        ],
      ),
    );
  }

  void _showErrorResult(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Eroare Scanare'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Înapoi la ecranul anterior
            },
            child: const Text('Închide'),
          ),
          ElevatedButton(
            onPressed: _resetScanner,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Încearcă din nou'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    Navigator.of(context).pop(); // Închide dialog-ul
    setState(() {
      _hasScanned = false;
      _isProcessing = false;
      _lastScannedCode = null;
      _scanResult = null;
    });
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Data necunoscută';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanează QR Prezență'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_controller != null)
            IconButton(
              onPressed: () => _controller!.toggleTorch(),
              icon: const Icon(Icons.flash_on),
              tooltip: 'Comută lanterna',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Pentru web sau platforme nesuportate, afișează un mesaj
    if (kIsWeb || _controller == null) {
      return _buildWebFallback();
    }

    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _controller!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _processQRCode(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        // Overlay cu instrucțiuni
        _buildScannerOverlay(),

        // Loading indicator
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Se procesează codul QR...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Scanarea QR nu este disponibilă pe web',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Pentru a scana coduri QR pentru prezență, te rog să folosești aplicația mobilă pe Android sau iOS.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Înapoi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Column(
      children: [
        // Top overlay
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black54,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Poziționează codul QR în cadru pentru a-ți înregistra prezența',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),

        // Middle area (scanning frame)
        Expanded(
          flex: 3,
          child: Row(
            children: [
              // Left overlay
              Expanded(
                child: Container(color: Colors.black54),
              ),
              // Scanning frame
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner indicators
                    ...List.generate(4, (index) {
                      final positions = [
                        const Alignment(-1, -1), // Top-left
                        const Alignment(1, -1),  // Top-right
                        const Alignment(-1, 1),  // Bottom-left
                        const Alignment(1, 1),   // Bottom-right
                      ];
                      
                      return Align(
                        alignment: positions[index],
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.green,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Right overlay
              Expanded(
                child: Container(color: Colors.black54),
              ),
            ],
          ),
        ),

        // Bottom overlay
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Asigură-te că QR-ul este clar vizibil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Anulează',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
