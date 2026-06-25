import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication_features.dart';
import '../models/medicine.dart';
import 'language_service.dart';
import '../main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Medicine Response
// ─────────────────────────────────────────────────────────────────────────────

/// Parsed response from POST /api/UserMedications.
/// The medication is always added when statusCode == 200/201.
/// [interactionWarnings] may contain safety warnings to show the user.
class AddMedicineResponse {
  final String? message;
  final int? userMedicationId;
  final String? medicationName;
  final String? dosageForm;
  final String? quantityUnit;
  final int? initialQuantity;
  final int? currentQuantity;
  final int? doseQuantity;
  final String? expiryDate;
  final bool expiryAdjusted;
  final String? expiryAdjustedNote;
  final bool isOpened;
  final String? openedDate;
  final int? afterOpeningDurationValue;
  final String? afterOpeningDurationUnit;
  final String? afterOpeningExpiryDate;
  final String? effectiveExpiryDate;
  final String? expiryReason;
  final String? afterOpeningSource;
  final String? afterOpeningWarning;
  final bool isCustomMedication;
  final bool? supportsInteractions;
  final bool? supportsIngredientWarnings;
  final String? customMedicationWarning;
  final List<String> interactionWarnings;

  const AddMedicineResponse({
    this.message,
    this.userMedicationId,
    this.medicationName,
    this.dosageForm,
    this.quantityUnit,
    this.initialQuantity,
    this.currentQuantity,
    this.doseQuantity,
    this.expiryDate,
    this.expiryAdjusted = false,
    this.expiryAdjustedNote,
    this.isOpened = false,
    this.openedDate,
    this.afterOpeningDurationValue,
    this.afterOpeningDurationUnit,
    this.afterOpeningExpiryDate,
    this.effectiveExpiryDate,
    this.expiryReason,
    this.afterOpeningSource,
    this.afterOpeningWarning,
    this.isCustomMedication = false,
    this.supportsInteractions,
    this.supportsIngredientWarnings,
    this.customMedicationWarning,
    this.interactionWarnings = const [],
  });

  bool get hasInteractionWarnings => interactionWarnings.isNotEmpty;

  factory AddMedicineResponse.fromJson(Map<String, dynamic> j) {
    final rawWarnings = j['interactionWarnings'];
    final warnings = rawWarnings is List
        ? rawWarnings.map((e) => e.toString()).toList()
        : <String>[];
    return AddMedicineResponse(
      message: j['message']?.toString(),
      userMedicationId: _parseNullableInt(
        j['userMedicationId'] ?? j['id'] ?? j['medicationId'],
      ),
      medicationName: (j['medicationName'] ?? j['name'])?.toString(),
      dosageForm: j['dosageForm']?.toString(),
      quantityUnit: j['quantityUnit']?.toString(),
      initialQuantity: _parseNullableInt(j['initialQuantity']),
      currentQuantity: _parseNullableInt(j['currentQuantity']),
      doseQuantity: _parseNullableInt(j['doseQuantity']),
      expiryDate: j['expiryDate']?.toString(),
      expiryAdjusted: j['expiryAdjusted'] as bool? ?? false,
      expiryAdjustedNote: j['expiryAdjustedNote']?.toString(),
      isOpened: j['isOpened'] as bool? ?? false,
      openedDate: j['openedDate']?.toString(),
      afterOpeningDurationValue: _parseNullableInt(
        j['afterOpeningDurationValue'],
      ),
      afterOpeningDurationUnit: j['afterOpeningDurationUnit']?.toString(),
      afterOpeningExpiryDate: j['afterOpeningExpiryDate']?.toString(),
      effectiveExpiryDate: j['effectiveExpiryDate']?.toString(),
      expiryReason: j['expiryReason']?.toString(),
      afterOpeningSource: j['afterOpeningSource']?.toString(),
      afterOpeningWarning: j['afterOpeningWarning']?.toString(),
      isCustomMedication: j['isCustomMedication'] as bool? ?? false,
      supportsInteractions: j['supportsInteractions'] as bool?,
      supportsIngredientWarnings: j['supportsIngredientWarnings'] as bool?,
      customMedicationWarning: j['customMedicationWarning']?.toString(),
      interactionWarnings: warnings,
    );
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

/// Service class for all UserMedications API calls
class UserMedicationsService {
  static const String _apiRoot = 'https://drugsafe.runasp.net/api';
  static const String _baseUrl =
      'https://drugsafe.runasp.net/api/UserMedications';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  static Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['data'] is Map<String, dynamic>) {
      return decoded['data'] as Map<String, dynamic>;
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  static List<dynamic> _decodeList(String body) {
    if (body.trim().isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] != null) {
      return ApiParse.listValue(decoded['data']);
    }
    if (decoded is Map && decoded['\$values'] != null) {
      return ApiParse.listValue(decoded['\$values']);
    }
    return const [];
  }

  static ApiException _parseFeatureError(
    http.Response response,
    String fallback,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['title'];
        if (message != null) {
          return ApiException(
            message.toString(),
            response.statusCode,
            response.body,
          );
        }
      }
    } catch (_) {}
    if (response.statusCode == 400) {
      return ApiException(
        'This action is not available right now. Check dose limits, stock, or timing.',
        response.statusCode,
        response.body,
      );
    }
    return ApiException(fallback, response.statusCode, response.body);
  }

  /// GET /api/UserMedications/myusermeds — fetch all user medications
  static Future<List<Medicine>> fetchAll(String token) async {
    final response = await http.get(
      LanguageService.appendLanguageQuery(Uri.parse('$_baseUrl/myusermeds')),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      try {
        // Helpful debug information removed
      } catch (_) {}
      List<dynamic> list;

      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        list = decoded['data'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('\$values')) {
        list = decoded['\$values'] as List<dynamic>;
      } else {
        list = [];
      }

      return list
          .map((json) => Medicine.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        'Failed to fetch medications',
        response.statusCode,
        response.body,
      );
    }
  }

  /// POST /api/UserMedications — create a new medication.
  /// Returns [AddMedicineResponse] which includes any interaction warnings.
  /// The medication is already persisted by the backend on success.
  static Future<AddMedicineResponse> create(
    String token,
    Medicine medicine,
  ) async {
    final response = await http.post(
      LanguageService.appendLanguageQuery(Uri.parse(_baseUrl)),
      headers: _headers(token),
      body: jsonEncode(medicine.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return AddMedicineResponse.fromJson(decoded);
        }
      } catch (_) {}
      // Fallback: success but unparseable body
      return const AddMedicineResponse();
    } else {
      throw ApiException(
        'Failed to create medication',
        response.statusCode,
        response.body,
      );
    }
  }

  /// POST /api/UserMedications/init — create a medication by name only (init).
  static Future<AddMedicineResponse> createByNameOnly(
    String token,
    String name, {
    bool isCustomMedication = false,
    String? dosageForm,
    String? quantityUnit,
  }) async {
    final response = await http.post(
      LanguageService.appendLanguageQuery(Uri.parse('$_baseUrl/init')),
      headers: _headers(token),
      body: jsonEncode({
        if (isCustomMedication) 'medicationId': null,
        'medicationName': name,
        'isCustomMedication': isCustomMedication,
        if (dosageForm != null) 'dosageForm': dosageForm,
        if (quantityUnit != null) 'quantityUnit': quantityUnit,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return AddMedicineResponse.fromJson(decoded);
        }
      } catch (_) {}
      return const AddMedicineResponse();
    } else {
      throw ApiException(
        'Failed to create medication by name only',
        response.statusCode,
        response.body,
      );
    }
  }

  /// GET /api/medications/{userMedId}/schedules — fetch schedules for a specific user medication
  static Future<dynamic> fetchSchedulesForUserMedication(
    String token,
    int userMedId,
  ) async {
    final response = await http.get(
      LanguageService.appendLanguageQuery(
        Uri.parse(
          'https://drugsafe.runasp.net/api/medications/$userMedId/schedules',
        ),
      ),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        'Failed to fetch schedules for medication $userMedId',
        response.statusCode,
        response.body,
      );
    }
  }

  /// PUT /api/UserMedications/{id} — update an existing medication
  static Future<Medicine> update(String token, Medicine medicine) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/${medicine.id}'),
      headers: _headers(token),
      body: jsonEncode(medicine.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final merged = <String, dynamic>{
            ...medicine.toJson(),
            ...decoded,
            'id': decoded['id'] ?? decoded['Id'] ?? medicine.id,
          };
          return Medicine.fromJson(merged);
        }
      }
      return medicine; // 204 No Content — return the local copy
    } else {
      throw ApiException(
        'Failed to update medication',
        response.statusCode,
        response.body,
      );
    }
  }

  /// POST /api/UserMedications/{id}/request-add-to-database
  static Future<void> requestAddToDatabase(
    String token,
    int userMedicationId,
  ) async {
    final response = await http.post(
      LanguageService.appendLanguageQuery(
        Uri.parse('$_baseUrl/$userMedicationId/request-add-to-database'),
      ),
      headers: _headers(token),
      body: '{}',
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw ApiException(
        'Failed to request adding medication to database',
        response.statusCode,
        response.body,
      );
    }
  }

  /// DELETE /api/UserMedications/{id} — delete a medication
  static Future<void> delete(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        'Failed to delete medication',
        response.statusCode,
        response.body,
      );
    }
  }

  /// DELETE /api/UserMedications/myusermeds — delete all user medications
  static Future<void> deleteMyUserMeds(String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/myusermeds'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        'Failed to delete user medications',
        response.statusCode,
        response.body,
      );
    }
  }

  static Uri _insightsUri(String path, {DateTime? from, DateTime? to}) {
    final dateFormatter = RegExp(r'T.*');
    final startDate = from?.toIso8601String().replaceFirst(dateFormatter, '');
    final endDate = to?.toIso8601String().replaceFirst(dateFormatter, '');

    return LanguageService.appendLanguageQuery(Uri.parse('$_apiRoot$path'), {
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
  }

  static Future<AdherenceSummaryModel> getAdherenceSummary(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await http.get(
      _insightsUri('/users/me/adherence-summary', from: from, to: to),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return AdherenceSummaryModel.fromJson(_decodeObject(response.body));
    }
    throw _parseFeatureError(response, 'Failed to load adherence summary');
  }

  static Future<List<DoseHistoryModel>> getDoseHistory(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await http.get(
      _insightsUri('/users/me/dose-history', from: from, to: to),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return _decodeList(response.body)
          .whereType<Map<String, dynamic>>()
          .map(DoseHistoryModel.fromJson)
          .toList();
    }
    throw _parseFeatureError(response, 'Failed to load dose history');
  }

  static Future<MedicationAdherenceModel> getMedicationAdherence(
    String token,
    int userMedicationId,
  ) async {
    final response = await http.get(
      LanguageService.appendLanguageQuery(
        Uri.parse('$_apiRoot/medications/$userMedicationId/adherence'),
      ),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return MedicationAdherenceModel.fromJson(_decodeObject(response.body));
    }
    throw _parseFeatureError(response, 'Failed to load medication adherence');
  }

  static Future<CabinetHealthModel> getCabinetHealth(String token) async {
    final response = await http.get(
      LanguageService.appendLanguageQuery(
        Uri.parse('$_apiRoot/users/me/cabinet-health'),
      ),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return CabinetHealthModel.fromJson(_decodeObject(response.body));
    }
    throw _parseFeatureError(response, 'Failed to load cabinet health');
  }

  static Future<List<MedicationIntakeLogModel>> getIntakeHistory(
    String token,
    int userMedicationId,
  ) async {
    final response = await http.get(
      LanguageService.appendLanguageQuery(
        Uri.parse(
          '$_apiRoot/user-medications/$userMedicationId/intake-history',
        ),
      ),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return _decodeList(response.body)
          .whereType<Map<String, dynamic>>()
          .map(MedicationIntakeLogModel.fromJson)
          .toList();
    }
    throw _parseFeatureError(response, 'Failed to load intake history');
  }

  static Future<MedicationIntakeLogModel?> takeNow(
    String token,
    int userMedicationId, {
    String? reason,
    String? notes,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiRoot/user-medications/$userMedicationId/take-now'),
          headers: _headers(token),
          body: jsonEncode({'reason': reason, 'notes': notes}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      if (response.body.isEmpty) return null;
      final decoded = _decodeObject(response.body);
      final intake = decoded['intake'] ?? decoded['Intake'];
      if (intake is Map<String, dynamic>) {
        return MedicationIntakeLogModel.fromJson(intake);
      }
      return null;
    }
    throw _parseFeatureError(response, 'Failed to record dose');
  }

  static Future<void> refillMedication(
    String token,
    int userMedicationId,
    int quantity,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_apiRoot/user-medications/$userMedicationId/refill'),
          headers: _headers(token),
          body: jsonEncode({'quantity': quantity}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }
    throw _parseFeatureError(response, 'Failed to add refill');
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  ApiException(this.message, this.statusCode, this.responseBody) {
    if (statusCode == 401) {
      triggerGlobalLogout();
    }
  }

  @override
  String toString() => '$message (HTTP $statusCode): $responseBody';
}

// ─────────────────────────────────────────────────────────────────────────────
// Take Dose Result Model
// ─────────────────────────────────────────────────────────────────────────────

/// Parsed response from POST /api/schedules/{scheduleId}/take
class TakeDoseResult {
  final bool succeeded;
  final String? error;
  final int scheduleId;
  final int? pillsDeducted;
  final int? remainingPills;
  final int? quantityDeducted;
  final int? remainingQuantity;
  final String? quantityUnit;
  final bool lowStockAlertCreated;

  TakeDoseResult({
    required this.succeeded,
    this.error,
    required this.scheduleId,
    this.pillsDeducted,
    this.remainingPills,
    this.quantityDeducted,
    this.remainingQuantity,
    this.quantityUnit,
    required this.lowStockAlertCreated,
  });

  factory TakeDoseResult.fromJson(Map<String, dynamic> j) {
    return TakeDoseResult(
      succeeded: j['succeeded'] as bool? ?? false,
      error: j['error']?.toString(),
      scheduleId: j['scheduleId'] as int? ?? 0,
      pillsDeducted: AddMedicineResponse._parseNullableInt(j['pillsDeducted']),
      remainingPills: AddMedicineResponse._parseNullableInt(
        j['remainingPills'],
      ),
      quantityDeducted: AddMedicineResponse._parseNullableInt(
        j['quantityDeducted'] ?? j['pillsDeducted'],
      ),
      remainingQuantity: AddMedicineResponse._parseNullableInt(
        j['remainingQuantity'] ?? j['remainingPills'],
      ),
      quantityUnit: j['quantityUnit']?.toString(),
      lowStockAlertCreated: j['lowStockAlertCreated'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedules Service — Take / Snooze / Skip
// ─────────────────────────────────────────────────────────────────────────────

/// Parsed response from POST /api/schedules/{scheduleId}/snooze
class SnoozeResult {
  final bool succeeded;
  final String? message;
  final String? error;

  SnoozeResult({required this.succeeded, this.message, this.error});

  factory SnoozeResult.fromJson(Map<String, dynamic> j) {
    return SnoozeResult(
      succeeded: j['succeeded'] as bool? ?? true,
      message: j['message']?.toString(),
      error: j['error']?.toString(),
    );
  }
}

class SchedulesService {
  static const String _baseUrl = 'https://drugsafe.runasp.net/api/schedules';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': '*/*',
    'Authorization': 'Bearer $token',
  };

  /// Shared error handler for 400/401/404 responses.
  static ApiException _parseError(http.Response response, String action) {
    if (response.statusCode == 401) {
      return ApiException(
        'Unauthorized. Please sign in again.',
        401,
        response.body,
      );
    }
    if (response.statusCode == 404) {
      return ApiException(
        'Schedule not found or access denied.',
        404,
        response.body,
      );
    }
    if (response.statusCode == 400) {
      try {
        final decoded = jsonDecode(response.body);
        final msg =
            decoded['message'] ??
            decoded['error'] ??
            decoded['title'] ??
            'Bad request.';
        return ApiException(msg.toString(), 400, response.body);
      } catch (_) {
        return ApiException('Bad request.', 400, response.body);
      }
    }
    return ApiException(
      'Failed to $action (${response.statusCode}).',
      response.statusCode,
      response.body,
    );
  }

  /// POST /api/schedules/{scheduleId}/take
  ///
  /// Marks a scheduled dose as taken. The backend deducts doseQuantity from
  /// the user's current quantity and optionally creates a low-stock alert.
  static Future<TakeDoseResult> takeDose(String token, int scheduleId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$scheduleId/take'),
          headers: _headers(token),
          body: '{}',
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return TakeDoseResult.fromJson(decoded);
    }
    throw _parseError(response, 'take dose');
  }

  /// POST /api/schedules/{scheduleId}/snooze?minutes={minutes}
  ///
  /// Snoozes a pending dose by specified minutes.
  /// Backend keeps status as Pending, increments snoozeCount, and shifts scheduledAt.
  static Future<SnoozeResult> snoozeDose(
    String token,
    int scheduleId,
    int minutes,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$scheduleId/snooze?minutes=$minutes'),
          headers: _headers(token),
          body: '{}',
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return SnoozeResult.fromJson(decoded);
          }
        } catch (_) {}
      }
      return SnoozeResult(
        succeeded: true,
        message: 'Reminder snoozed for $minutes minutes',
      );
    }
    throw _parseError(response, 'snooze dose');
  }

  /// POST /api/schedules/{scheduleId}/skip
  ///
  /// Skips a pending dose. Backend marks status as Missed.
  /// Flutter treats this as Missed — there is no "Skipped" status.
  static Future<void> skipDose(
    String token,
    int scheduleId, {
    String? reason,
    String? note,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$scheduleId/skip'),
          headers: _headers(token),
          body: jsonEncode({'reason': reason, 'note': note}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }
    throw _parseError(response, 'skip dose');
  }
}
