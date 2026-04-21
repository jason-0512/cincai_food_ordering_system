import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuditService {
  static final _db = Supabase.instance.client;

  static Future<void> log({
    required int adminId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      await _db.from('audit_log').insert({
        'admin_id': adminId,
        'action_taken': action,
        'entity_type': entityType,
        'affected_id': entityId,
        'old_v': oldValue,
        'new_v': newValue,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('CRITICAL: Audit log failed: $e');
    }
  }
}