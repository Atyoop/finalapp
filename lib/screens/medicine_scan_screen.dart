import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/medicine.dart';
import '../providers/user_provider.dart';
import '../services/medicine_scan_service.dart';
import '../services/user_medications_service.dart';
import '../widgets/interaction_warning_dialog.dart';
import 'add_reminder_screen.dart';

class MedicineScanScreen extends StatefulWidget {
  const MedicineScanScreen({super.key});

  @override
  State<MedicineScanScreen> createState() => _MedicineScanScreenState();
}

class _MedicineScanScreenState extends State<MedicineScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  ImageSource? _activeSource;
  String _title = 'Scan Medicine';
  String _message = 'Choose how you want to scan the medicine box.';
  late final AnimationController _animationController;
  late final Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _lineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    if (_isProcessing) return;

    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) {
      _showError('Please sign in to scan medicine.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _activeSource = source;
      _title = source == ImageSource.camera
          ? 'Opening Camera'
          : 'Opening Gallery';
      _message = source == ImageSource.camera
          ? 'Capture the front of the medicine box.'
          : 'Choose a clear medication image from your gallery.';
    });

    try {
      final pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (!mounted) return;
      if (pickedImage == null) {
        setState(() {
          _isProcessing = false;
          _activeSource = null;
          _title = 'Scan Medicine';
          _message = source == ImageSource.camera
              ? 'No image captured. Try again when you are ready.'
              : 'No image selected. Try again when you are ready.';
        });
        return;
      }

      debugPrint('[MedicineScan] picked image path: ${pickedImage.path}');
      await _processImage(token, File(pickedImage.path));
    } on MedicineScanException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on PlatformException catch (e) {
      debugPrint('[MedicineScan] image picker permission/error: $e');
      if (!mounted) return;
      _showError(
        e.code == 'camera_access_denied' || e.code == 'photo_access_denied'
            ? 'Permission is needed to select or capture a medicine image.'
            : 'Could not open image picker. Please try again.',
      );
    } catch (e) {
      debugPrint('[MedicineScan] image selection/processing error: $e');
      if (!mounted) return;
      _showError('Could not scan medicine. Please try again.');
    }
  }

  Future<void> _processImage(String token, File image) async {
    setState(() {
      _title = 'Scanning Medicine';
      _message = 'Uploading and detecting the medicine name...';
    });

    try {
      final scanResponse = await MedicineScanService.scanMedicineImage(
        token,
        image,
      );
      final medicationName = scanResponse.medicationName?.trim() ?? '';
      if (!mounted) return;
      if (!scanResponse.success || medicationName.isEmpty) {
        _showError(
          scanResponse.message?.trim().isNotEmpty == true
              ? scanResponse.message!.trim()
              : 'Could not detect medicine name. Please try another image.',
        );
        return;
      }

      debugPrint('[MedicineScan] detected medication name: $medicationName');
      await _initializeDetectedMedication(token, medicationName);
    } on MedicineScanException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      debugPrint('[MedicineScan] scan flow error: $e');
      if (!mounted) return;
      _showError('Could not scan medicine. Please try again.');
    }
  }

  Future<void> _initializeDetectedMedication(
    String token,
    String medicationName,
  ) async {
    setState(() {
      _title = 'Preparing Details';
      _message = 'Creating a medication draft for $medicationName...';
    });

    try {
      final initResponse = await MedicineScanService.initializeMedication(
        token,
        medicationName,
      );

      if (!mounted) return;
      if (initResponse.hasInteractionWarnings) {
        await showInteractionWarningDialog(
          context,
          initResponse.interactionWarnings,
        );
      }

      if (!mounted) return;
      final initialMedicine = _buildInitialMedicine(
        id: initResponse.userMedicationId,
        name: initResponse.medicationName ?? medicationName,
      );

      if (initialMedicine.id.isEmpty) {
        _showError('Could not prepare medicine details. Please try again.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddReminderScreen(initialMedicine: initialMedicine),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      debugPrint('[MedicineScan] init error: $e');
      _showError(
        'Detected $medicationName, but could not prepare medicine details. ${_friendlyApiMessage(e)}',
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('[MedicineScan] init error: $e');
      _showError(
        'Detected $medicationName, but could not prepare medicine details.',
      );
    }
  }

  String _friendlyApiMessage(ApiException error) {
    final body = error.responseBody.trim();
    if (body.isEmpty) return '';
    return body.length > 120 ? body.substring(0, 120) : body;
  }

  Medicine _buildInitialMedicine({required int? id, required String name}) {
    final now = DateTime.now();
    return Medicine(
      id: id?.toString() ?? '',
      name: name,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      deadlineDate: now,
      expiryDate: now.add(const Duration(days: 365)),
      frequency: '',
      time: const TimeOfDay(hour: 8, minute: 0),
      doseAmount: '1 Tablet',
      initialStock: 0,
      dosageForm: 'tablet',
      quantityUnit: 'tablet',
      initialQuantity: 0,
      currentQuantity: 0,
      doseQuantity: 1,
      currentPillCount: 0,
      initialPillCount: 0,
      pillsPerDose: 1,
    );
  }

  void _showError(String message) {
    setState(() {
      _isProcessing = false;
      _activeSource = null;
      _title = 'Scan Medicine';
      _message = 'Choose how you want to scan the medicine box.';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Medicine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                  AnimatedBuilder(
                    animation: _lineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _lineAnimation.value * 240 + 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primaryTeal.withValues(alpha: 0.8),
                                const Color(0xFF3A9EA5),
                                AppColors.primaryTeal.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Icon(
                      Icons.document_scanner_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.camera),
                    icon: _isProcessing && _activeSource == ImageSource.camera
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      _isProcessing && _activeSource == ImageSource.camera
                          ? 'Working...'
                          : 'Take Photo Using Camera',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      disabledBackgroundColor: AppColors.primaryTeal.withValues(
                        alpha: 0.5,
                      ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.gallery),
                    icon: _isProcessing && _activeSource == ImageSource.gallery
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.photo_library_outlined,
                            color: _isProcessing
                                ? Colors.white54
                                : Colors.white,
                          ),
                    label: Text(
                      _isProcessing && _activeSource == ImageSource.gallery
                          ? 'Working...'
                          : 'Choose Photo From Gallery',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white54,
                      side: BorderSide(
                        color: Colors.white.withValues(
                          alpha: _isProcessing ? 0.25 : 0.75,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
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

  Widget _buildCorner(Alignment alignment) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
