import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/medicine_scan_response.dart';
import 'user_medications_service.dart';

class MedicineScanService {
  static const String _scanUrl =
      'https://drugsafe.runasp.net/api/medicine-scan/image';
  static const List<String> _imageFieldCandidates = [
    'image',
    'imageFile',
    'file',
  ];

  static Future<MedicineScanResponse> scanMedicineImage(
    String token,
    File image,
  ) async {
    debugPrint('[MedicineScan] request URL: $_scanUrl');
    debugPrint('[MedicineScan] selected image path: ${image.path}');
    if (!await image.exists()) {
      throw const MedicineScanException('Selected image file was not found.');
    }
    final imageFile = await _prepareImageFile(image);

    try {
      http.Response? lastResponse;
      dynamic lastDecoded;

      for (final fieldName in _imageFieldCandidates) {
        debugPrint('[MedicineScan] multipart image field: $fieldName');
        final response = await _sendMultipartRequest(
          token: token,
          image: image,
          imageFile: imageFile,
          fieldName: fieldName,
        );

        debugPrint('[MedicineScan] response status: ${response.statusCode}');
        debugPrint('[MedicineScan] response body: ${response.body}');

        final decoded = _tryDecodeJson(response.body);
        lastResponse = response;
        lastDecoded = decoded;

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (decoded is Map<String, dynamic>) {
            return MedicineScanResponse.fromJson(decoded);
          }
          throw const MedicineScanException(
            'Scan response was not in the expected format.',
          );
        }

        if (!_shouldRetryWithNextField(response.statusCode, decoded)) {
          break;
        }
      }

      final response = lastResponse;
      throw MedicineScanException(
        _messageFromResponse(lastDecoded) ??
            'Failed to scan medicine image (HTTP ${response?.statusCode ?? 'unknown'}).',
        statusCode: response?.statusCode,
        responseBody: response?.body,
      );
    } on SocketException catch (e) {
      debugPrint('[MedicineScan] network error: $e');
      throw const MedicineScanException(
        'Network error while uploading image. Please check your connection.',
      );
    } on HttpException catch (e) {
      debugPrint('[MedicineScan] upload HTTP error: $e');
      throw MedicineScanException('Upload error: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('[MedicineScan] response parse error: $e');
      throw const MedicineScanException(
        'Could not read the scan response from the server.',
      );
    } on MedicineScanException {
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('[MedicineScan] upload timeout: $e');
      throw const MedicineScanException(
        'Image scan timed out. Please try again.',
      );
    } catch (e) {
      debugPrint('[MedicineScan] upload error: $e');
      throw const MedicineScanException(
        'Could not upload the image. Please try again.',
      );
    }
  }

  static Future<AddMedicineResponse> initializeMedication(
    String token,
    String medicationName,
  ) {
    return UserMedicationsService.createByNameOnly(token, medicationName);
  }

  static Future<http.Response> _sendMultipartRequest({
    required String token,
    required File image,
    required _PreparedImageFile imageFile,
    required String fieldName,
  }) async {
    debugPrint('[MedicineScan] file extension: ${imageFile.extension}');
    debugPrint('[MedicineScan] detected MIME type: ${imageFile.mimeType}');
    debugPrint('[MedicineScan] upload filename: ${imageFile.filename}');

    final request = http.MultipartRequest('POST', Uri.parse(_scanUrl))
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          image.path,
          filename: imageFile.filename,
          contentType: imageFile.contentType,
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    return http.Response.fromStream(streamed);
  }

  static Future<_PreparedImageFile> _prepareImageFile(File image) async {
    final originalFilename = _basename(image.path);
    final extensionFromPath = _extension(image.path);
    final detectedExtension = await _detectImageExtension(
      image,
      extensionFromPath,
    );

    final contentType = switch (detectedExtension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      _ => null,
    };

    if (contentType == null) {
      debugPrint(
        '[MedicineScan] unsupported file extension: $extensionFromPath',
      );
      throw const MedicineScanException(
        'Please choose a JPG or PNG medicine image.',
      );
    }

    final filename = _hasSupportedImageExtension(originalFilename)
        ? originalFilename
        : 'medicine_scan_${DateTime.now().millisecondsSinceEpoch}.$detectedExtension';

    return _PreparedImageFile(
      extension: detectedExtension,
      mimeType: contentType.mimeType,
      filename: filename,
      contentType: contentType,
    );
  }

  static Future<String> _detectImageExtension(
    File image,
    String extensionFromPath,
  ) async {
    final normalized = extensionFromPath.toLowerCase();
    if (normalized == 'jpg' || normalized == 'jpeg' || normalized == 'png') {
      return normalized;
    }

    final bytes = await image
        .openRead(0, 12)
        .fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'png';
    }
    return normalized;
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash == -1 ? normalized : normalized.substring(slash + 1);
  }

  static String _extension(String path) {
    final filename = _basename(path);
    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  static bool _hasSupportedImageExtension(String filename) {
    final ext = _extension(filename);
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  static dynamic _tryDecodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String? _messageFromResponse(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final direct =
        (decoded['message'] ??
                decoded['error'] ??
                decoded['title'] ??
                decoded['detail'])
            ?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct;

    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return null;
  }

  static bool _shouldRetryWithNextField(int statusCode, dynamic decoded) {
    if (statusCode != 400 && statusCode != 415 && statusCode != 422) {
      return false;
    }

    final message = _messageFromResponse(decoded)?.toLowerCase() ?? '';
    if (message.isEmpty) return true;
    return message.contains('file') ||
        message.contains('image') ||
        message.contains('form') ||
        message.contains('required');
  }
}

class _PreparedImageFile {
  final String extension;
  final String mimeType;
  final String filename;
  final MediaType contentType;

  const _PreparedImageFile({
    required this.extension,
    required this.mimeType,
    required this.filename,
    required this.contentType,
  });
}

class MedicineScanException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  const MedicineScanException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    if (statusCode == null) return message;
    return '$message (HTTP $statusCode)';
  }
}
