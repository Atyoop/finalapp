import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/pharmacy_model.dart';
import '../services/location_service.dart';
import '../services/pharmacy_service.dart';

class FindPharmacyScreen extends StatefulWidget {
  const FindPharmacyScreen({super.key});

  @override
  State<FindPharmacyScreen> createState() => _FindPharmacyScreenState();
}

class _FindPharmacyScreenState extends State<FindPharmacyScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  LocationResult? _locationResult;
  List<PharmacyModel> _pharmacies = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await LocationService.getCurrentLocation();
    _locationResult = result;

    if (result.status == LocationStatus.success) {
      _searchPharmacies(result.latitude, result.longitude);
    } else {
      setState(() {
        _isLoading = false;
        _error = result.message;
      });
    }
  }

  Future<void> _searchPharmacies(double lat, double lng) async {
    try {
      final pharmacies = await PharmacyService.searchNearbyPharmacies(
        latitude: lat,
        longitude: lng,
      );

      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
        _error = null;
      });

      _fitMapBounds(lat, lng, pharmacies);
    } on PharmacyException catch (e) {
      final cached = PharmacyService.loadCached();
      if (cached.isNotEmpty) {
        setState(() {
          _pharmacies = cached;
          _isLoading = false;
          _error = null;
        });
        _fitMapBounds(lat, lng, cached);
      } else {
        setState(() {
          _isLoading = false;
          _error = e.message;
        });
      }
    }
  }

  void _fitMapBounds(
    double userLat,
    double userLng,
    List<PharmacyModel> pharmacies,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mapReady) return;

      if (pharmacies.isEmpty) {
        _mapController.move(LatLng(userLat, userLng), 14);
        return;
      }

      double minLat = userLat, maxLat = userLat;
      double minLng = userLng, maxLng = userLng;

      for (final p in pharmacies) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final sw = LatLng(minLat - 0.005, minLng - 0.005);
      final ne = LatLng(maxLat + 0.005, maxLng + 0.005);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(sw, ne),
          padding: const EdgeInsets.all(60),
        ),
      );
    });
  }

  void _openDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Find Pharmacy',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryTeal),
            SizedBox(height: 16),
            Text(
              'Finding nearby pharmacies...',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null && _pharmacies.isEmpty) {
      return _buildError();
    }

    return Column(
      children: [
        _buildMap(),
        _buildListHeader(),
        Expanded(child: _buildPharmacyList()),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _error?.contains('denied') == true
                  ? Icons.location_off_rounded
                  : _error?.contains('internet') == true
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: 64,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_error?.contains('deniedForever') == true ||
                _error?.contains('denied forever') == true ||
                _error?.contains('permanently denied') == true) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await LocationService.openAppSettings();
                },
                child: Text(
                  context.l10n.t('openAppSettings'),
                  style: const TextStyle(color: AppColors.primaryTeal),
                ),
              ),
            ],
            if (_error?.contains('GPS') == true ||
                _error?.contains('disabled') == true) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await LocationService.openLocationSettings();
                },
                child: Text(
                  context.l10n.t('enableGps'),
                  style: const TextStyle(color: AppColors.primaryTeal),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _requestLocation,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.t('tryAgain')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final result = _locationResult;
    if (result == null || result.status != LocationStatus.success) {
      return Container(
        height: 200,
        color: Colors.grey[100],
        child: Center(
          child: Text(
            context.l10n.t('mapUnavailable'),
            style: const TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    final userPos = LatLng(result.latitude, result.longitude);

    return SizedBox(
      height: 250,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: userPos,
          initialZoom: 14,
          onTap: (_, __) {},
          onMapReady: () {
            _mapReady = true;
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.final88',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: userPos,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              for (final pharmacy in _pharmacies)
                Marker(
                  point: LatLng(pharmacy.latitude, pharmacy.longitude),
                  child: GestureDetector(
                    onTap: () => _showPharmacyDetails(pharmacy),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryTeal,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        color: AppColors.primaryTeal,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            'Nearby Pharmacies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (_pharmacies.isNotEmpty)
            Text(
              '${_pharmacies.length} found',
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
        ],
      ),
    );
  }

  Widget _buildPharmacyList() {
    if (_pharmacies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_pharmacy_outlined,
              size: 48,
              color: AppColors.textGrey,
            ),
            SizedBox(height: 12),
            Text(
              'No pharmacies found nearby',
              style: TextStyle(fontSize: 15, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = _pharmacies[index];
        return _buildPharmacyCard(pharmacy);
      },
    );
  }

  Widget _buildPharmacyCard(PharmacyModel pharmacy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showPharmacyDetails(pharmacy),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.primaryTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacy.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pharmacy.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pharmacy.address.isEmpty
                                    ? 'Pharmacy'
                                    : 'Open now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textGrey.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              pharmacy.formattedDistance,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey.withValues(
                                  alpha: 0.8,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPharmacyDetails(PharmacyModel pharmacy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.primaryTeal,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pharmacy.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  pharmacy.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _detailChip(
                      Icons.location_on_outlined,
                      pharmacy.formattedDistance,
                      AppColors.primaryTeal,
                    ),
                    _detailChip(
                      Icons.map_outlined,
                      '${pharmacy.latitude.toStringAsFixed(4)}, ${pharmacy.longitude.toStringAsFixed(4)}',
                      AppColors.textGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openDirections(pharmacy.latitude, pharmacy.longitude);
                    },
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(
                      context.l10n.t('openDirections'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailChip(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
