import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

class LocationCapture {
  const LocationCapture({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;

  LatLng get point => LatLng(latitude, longitude);
}

typedef LocationCaptureLoader = Future<LocationCapture?> Function();

class WebLocationCaptureScreen extends StatefulWidget {
  const WebLocationCaptureScreen({
    super.key,
    this.captureLocation,
    this.showMap = true,
  });

  final LocationCaptureLoader? captureLocation;
  final bool showMap;

  @override
  State<WebLocationCaptureScreen> createState() =>
      _WebLocationCaptureScreenState();
}

class _WebLocationCaptureScreenState extends State<WebLocationCaptureScreen> {
  final MapController _mapController = MapController();

  LocationCapture? _capture;
  bool _isLoading = false;
  String? _errorMessage;

  Future<LocationCapture?> _loadCurrentLocation() async {
    final position = await LocationService.getCurrentPosition(
      preferLastKnown: false,
    );
    if (position == null) return null;

    return LocationCapture(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: DateTime.now(),
    );
  }

  Future<void> _captureLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final capture = await (widget.captureLocation ?? _loadCurrentLocation)();
      if (!mounted) return;

      if (capture == null) {
        setState(() {
          _errorMessage = '현재 위치를 가져오지 못했습니다. 브라우저의 위치 권한을 확인하고 다시 시도해 주세요.';
        });
        return;
      }

      setState(() {
        _capture = capture;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.showMap) {
          _mapController.move(capture.point, 17);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = '위치 확인 중 오류가 발생했습니다. HTTPS 주소인지와 브라우저 권한을 확인해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = _capture;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  const SizedBox(height: 20),
                  _CaptureCard(
                    isLoading: _isLoading,
                    capture: capture,
                    errorMessage: _errorMessage,
                    onCapture: _captureLocation,
                  ),
                  if (capture != null && widget.showMap) ...[
                    const SizedBox(height: 16),
                    _LocationMap(controller: _mapController, capture: capture),
                  ],
                  const SizedBox(height: 16),
                  const _ExperimentNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.accessible_forward_rounded,
              color: Color(0xFF047857),
              size: 30,
            ),
            SizedBox(width: 10),
            Text(
              'FlatWay',
              style: TextStyle(
                color: Color(0xFF064E3B),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '설치 없이 현재 위치를 기록해 보세요',
          style: TextStyle(
            color: Color(0xFF10231D),
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '버튼을 누르면 브라우저가 위치 권한을 요청합니다. 확인한 위치는 이 화면에만 표시되며 데이터베이스에는 전송하지 않습니다.',
          style: TextStyle(
            color: Color(0xFF52645E),
            fontSize: 16,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.isLoading,
    required this.capture,
    required this.errorMessage,
    required this.onCapture,
  });

  final bool isLoading;
  final LocationCapture? capture;
  final String? errorMessage;
  final VoidCallback onCapture;

  String _formatTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final current = capture;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD8E4DF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('capture-location-button'),
              onPressed: isLoading ? null : onCapture,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                isLoading
                    ? '현재 위치 확인 중…'
                    : current == null
                    ? '현재 위치 기록'
                    : '현재 위치 다시 기록',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(
                  errorMessage!,
                  key: const Key('location-error'),
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (current != null) ...[
              const SizedBox(height: 18),
              const Text(
                '방금 확인한 위치',
                style: TextStyle(
                  color: Color(0xFF10231D),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ValueChip(
                    label: '위도',
                    value: current.latitude.toStringAsFixed(6),
                  ),
                  _ValueChip(
                    label: '경도',
                    value: current.longitude.toStringAsFixed(6),
                  ),
                  _ValueChip(
                    label: '정확도',
                    value: '약 ${current.accuracy.round()}m',
                  ),
                  _ValueChip(
                    label: '확인 시각',
                    value: _formatTimestamp(current.capturedAt),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: Color(0xFF24463A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocationMap extends StatelessWidget {
  const _LocationMap({required this.controller, required this.capture});

  final MapController controller;
  final LocationCapture capture;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: capture.point,
            initialZoom: 17,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.physicalspark.flatway.web-spike',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: capture.point,
                  width: 52,
                  height: 52,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF047857),
                    size: 48,
                    shadows: [Shadow(color: Colors.white, blurRadius: 5)],
                  ),
                ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperimentNote extends StatelessWidget {
  const _ExperimentNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Color(0xFF047857)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '이번 실험의 질문: 링크를 받은 사용자가 앱을 설치하지 않고도 자신의 위치를 확인하고, FlatWay에 정보를 남길 준비를 할 수 있는가?',
              style: TextStyle(
                color: Color(0xFF24463A),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
