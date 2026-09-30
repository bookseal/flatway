import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://wevesokdfrrtfmjbcprq.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_LEd-uwmLGwAGRbNA9tu4OA_0xshEJU1';
  static const String _pendingHazardsKey = 'pending_offline_hazards';
  static bool _readOnlyMode = false;

  static Future<void> initialize({bool readOnlyMode = false}) async {
    _readOnlyMode = readOnlyMode;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    if (!_readOnlyMode) {
      syncPendingHazards();
    }
  }

  static bool get isReadOnly => _readOnlyMode;

  static SupabaseClient get client => Supabase.instance.client;

  // Fetch all hazard reports from Supabase
  static Future<List<Map<String, dynamic>>> fetchHazards() async {
    if (_readOnlyMode) return _webPreviewHazards();

    try {
      final data = await client
          .from('hazards')
          .select('*')
          .order('reported_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching hazards from Supabase: $e');
      return [];
    }
  }

  // Fetch all building accessibility data from Supabase
  static Future<List<Map<String, dynamic>>> fetchBuildings() async {
    if (_readOnlyMode) return [];

    try {
      final data = await client.from('buildings').select('*');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching buildings from Supabase: $e');
      return [];
    }
  }

  // Upload hazard photo bytes to Supabase Storage
  static Future<String?> uploadHazardPhotoBytes(Uint8List bytes) async {
    if (_readOnlyMode) {
      debugPrint('Photo upload skipped in read-only mode.');
      return null;
    }
    try {
      final fileName = 'hazard_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage
          .from('hazard-photos')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final publicUrl = client.storage
          .from('hazard-photos')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading photo to Supabase Storage: $e');
      return null;
    }
  }

  // Submit a new hazard report to Supabase with offline queue fallback
  static Future<bool> insertHazard(Map<String, dynamic> hazardData) async {
    if (_readOnlyMode) {
      debugPrint('Hazard insert skipped in read-only mode.');
      return false;
    }
    try {
      await client.from('hazards').insert(hazardData);
      syncPendingHazards();
      return true;
    } catch (e) {
      debugPrint(
        'Error inserting hazard to Supabase. Saving to offline queue: $e',
      );
      await _savePendingOfflineHazard(hazardData);
      return true; // Saved locally
    }
  }

  // Save offline pending report to SharedPreferences
  static Future<void> _savePendingOfflineHazard(
    Map<String, dynamic> hazardData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_pendingHazardsKey) ?? [];
      list.add(jsonEncode(hazardData));
      await prefs.setStringList(_pendingHazardsKey, list);
    } catch (e) {
      debugPrint('Error saving offline hazard: $e');
    }
  }

  // Sync queued offline reports to Supabase when network is restored
  static Future<void> syncPendingHazards() async {
    if (_readOnlyMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_pendingHazardsKey) ?? [];
      if (list.isEmpty) return;

      final List<String> remaining = [];
      for (final itemStr in list) {
        try {
          final Map<String, dynamic> map = jsonDecode(itemStr);
          await client.from('hazards').insert(map);
        } catch (e) {
          debugPrint('Failed to sync item, keeping in offline queue: $e');
          remaining.add(itemStr);
        }
      }
      await prefs.setStringList(_pendingHazardsKey, remaining);
      debugPrint(
        'Offline hazards sync cycle completed. Remaining: ${remaining.length}',
      );
    } catch (e) {
      debugPrint('Error in syncPendingHazards: $e');
    }
  }

  static List<Map<String, dynamic>> _webPreviewHazards() {
    final now = DateTime.now().toUtc();
    return [
      {
        'id': 'Gyeyang_hazard_1',
        'type': 'step',
        'latitude': 37.5349,
        'longitude': 126.7224,
        'step_height_cm': 4.5,
        'severity': 'high',
        'description': '작전역 4번 출구 앞 보도 경계석 단차가 높아 휠체어 진입이 어려운 구간',
        'is_verified': true,
        'reported_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'status': 'scheduled',
      },
      {
        'id': 'Gyeyang_hazard_2',
        'type': 'damage',
        'latitude': 37.5365,
        'longitude': 126.7235,
        'step_height_cm': null,
        'severity': 'medium',
        'description': '작전여고 통학로 보도블록 파손 및 요철이 있는 구간',
        'is_verified': true,
        'reported_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'status': 'resolved',
      },
      {
        'id': 'Gyeyang_hazard_3',
        'type': 'obstacle',
        'latitude': 37.5358,
        'longitude': 126.7218,
        'step_height_cm': null,
        'severity': 'high',
        'description': '횡단보도 앞 적치물로 통행이 어려운 구간',
        'is_verified': false,
        'reported_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'status': 'reported',
      },
      {
        'id': 'Gyeyang_hazard_4',
        'type': 'slope',
        'latitude': 37.5372,
        'longitude': 126.7245,
        'step_height_cm': null,
        'severity': 'low',
        'description': '수동 휠체어 이용 시 주의가 필요한 경사 구간',
        'is_verified': true,
        'reported_at': now
            .subtract(const Duration(hours: 12))
            .toIso8601String(),
        'status': 'processing',
      },
    ];
  }
}
