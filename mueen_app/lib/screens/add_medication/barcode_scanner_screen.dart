import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../dialogs/add_medication/barcode_not_found_bottom_sheet.dart';
import '../../models/medication.dart';
import '../../services/api_service.dart';
import 'medication_found_confirmation_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final int elderId;
  final String elderName;

  const BarcodeScannerScreen({
    super.key,
    required this.elderId,
    required this.elderName,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isFlashlightOn = false;
  bool _isProcessing = false;
  bool _isLocked = false;

  String _normalizeDigitsToGtin14(String digits) {
    if (digits.isEmpty) return '';

    if (digits.length == 14) return digits;

    if (digits.length == 13 || digits.length == 12 || digits.length == 8) {
      return digits.padLeft(14, '0');
    }

    if (digits.length > 14) {
      return digits.substring(digits.length - 14);
    }

    return '';
  }

  String _extractGtinFromRaw(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';

    final gs1Match = RegExp(r'01(\d{14})').firstMatch(cleaned);
    if (gs1Match != null) {
      return gs1Match.group(1)!;
    }

    return _normalizeDigitsToGtin14(cleaned);
  }

  Future<void> _showBarcodeNotFoundBottomSheet() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeNotFoundBottomSheet(
        onTryAgain: () {
          Navigator.pop(context);
          _resumeScan();
        },
        onToggleFlashlight: () async {
          setState(() {
            _isFlashlightOn = !_isFlashlightOn;
          });
          await _controller.toggleTorch();
          if (!mounted) return;
          Navigator.pop(context);
          _resumeScan();
        },
        onManualEntry: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _resumeScan() {
    setState(() {
      _isProcessing = false;
      _isLocked = false;
    });
    _controller.start();
  }

  Future<void> _handleMedicationFound(Medication medication) async {
    await _controller.stop();

    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationFoundConfirmationScreen(
          elderId: widget.elderId,
          catalogMedicationId: medication.id,
          medicationName: medication.brandNameAr,
          imageUrl: '',
          details: {
            'طريقة الاستخدام': medication.routeAr ?? 'غير محدد',
            'الشكل الدوائي': medication.dosageForm ?? 'غير محدد',
            'التركيز': medication.dosageStrength ?? 'غير محدد',
            'المادة الفعالة': medication.genericNameEn ?? 'غير محدد',
          },
          usageNote: medication.foodGuideAr,
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isLocked) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue ?? '';
      if (rawValue.isEmpty) continue;

      final gtin = _extractGtinFromRaw(rawValue);
      if (gtin.isEmpty) continue;

      setState(() {
        _isProcessing = true;
        _isLocked = true;
      });

      try {
        final medication = await ApiService.getMedicationByGtin(gtin: gtin);

        if (medication != null) {
          await _handleMedicationFound(medication);
          return;
        } else {
          await _controller.stop();
          setState(() {
            _isProcessing = false;
            _isLocked = false;
          });
          await _showBarcodeNotFoundBottomSheet();
          return;
        }
      } catch (e) {
        if (!mounted) return;
        await _controller.stop();
        setState(() {
          _isProcessing = false;
          _isLocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر قراءة الباركود أو البحث عن الدواء'),
          ),
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'مسح الباركود',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isFlashlightOn = !_isFlashlightOn;
                    });
                    await _controller.toggleTorch();
                  },
                ),
              ],
            ),
          ),
          Center(
            child: IgnorePointer(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 250,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            left: 24,
            right: 24,
            child: Column(
              children: [
                const Text(
                  'وجّه الكاميرا نحو الباركود الموجود على علبة الدواء',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'جارٍ التحقق من الدواء...',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
