import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cincai_food_ordering_system/services/audit_service.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // User Management (Customer)
  // ================= SIGN UP =================
  static Future<String?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final cleanPhone = phone.trim();
      final cleanEmail = email.trim();

      // check duplicate email
      final existing = await _client
          .from('users')
          .select('email')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (existing != null) {
        return "Email already exists";
      }

      // check duplicate phone
      final existingPhone = await _client
          .from('users')
          .select('phone')
          .eq('phone', cleanPhone)
          .maybeSingle();

      if (existingPhone != null) {
        return "Mobile number already exists";
      }

      await _client.from('users').insert({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password_hash': password,
        'user_role': 'member',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= LOGIN =================
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _client
          .from('users')
          .select('id, email, user_role')
          .eq('email', email.trim())
          .eq('password_hash', password)
          .maybeSingle();

      return data;
    } catch (e) {
      return null;
    }
  }

  // ================= GET PROFILE =================
  static Future<Map<String, dynamic>?> getProfile(String email) async {
    try {
      return await _client
          .from('users')
          .select('id, name, email')
          .eq('email', email.trim())
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  // ================= UPDATE PROFILE =================
  static Future<String?> updateProfile({
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      final cleanPhone = phone.trim();

      final existingPhone = await _client
          .from('users')
          .select('email')
          .eq('phone', cleanPhone)
          .neq('email', email.trim())
          .maybeSingle();

      if (existingPhone != null) {
        return "Phone number already in use";
      }

      await _client
          .from('users')
          .update({'name': name.trim(), 'phone': cleanPhone})
          .eq('email', email.trim());

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= UPDATE EMAIL =================
  static Future<String?> updateEmail({
    required String oldEmail,
    required String newEmail,
  }) async {
    try {
      await _client
          .from('users')
          .update({'email': newEmail.trim()})
          .eq('email', oldEmail.trim());

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= UPDATE PASSWORD =================
  static Future<String?> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _client
          .from('users')
          .update({'password_hash': newPassword})
          .eq('email', email.trim());

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= DELETE ACCOUNT =================
  static Future<String?> deleteAccount(String email) async {
    try {
      await _client.from('users').delete().eq('email', email.trim());

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= SIGN OUT =================
  static Future<void> signOut() async {
    // No Supabase auth used (table-based login system)
  }

  // Promotion Management (Admin)
  // ================= CREATE NEW PROMO =================
  static Future<String?> createPromotion({
    required int adminId,
    required String promotionCode,
    required String promotionName,
    required double minSpent,
    required String discountType,
    required double discountValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final bool isActive = _computeIsActive(startDate, endDate);
      final newData = {
        'promotion_code': promotionCode.trim().toUpperCase(),
        'promotion_name': promotionName.trim(),
        'min_spent': minSpent,
        'discount_type': discountType,
        'discount_value': discountValue,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate.toUtc().toIso8601String(),
        'is_active': isActive,
      };

      final inserted = await _client
          .from('promotion')
          .insert(newData)
          .select('promotion_id')
          .single();

      await AuditService.log(
        adminId: adminId,
        action: 'promo.create',
        entityType: 'promotion',
        entityId: inserted['promotion_id'].toString(),
        newValue: newData,
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= GET PROMO =================
  static Future<List<Map<String, dynamic>>> getAllPromotions() async {
    try {
      final List<dynamic> rows = await _client
          .from('promotion')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> promos = rows
          .cast<Map<String, dynamic>>();

      for (final promo in promos) {
        final DateTime end = DateTime.parse(promo['end_date']).toLocal();
        final DateTime start = DateTime.parse(promo['start_date']).toLocal();

        final bool isManuallyInactive = promo['is_active'] == false;
        final bool shouldBeActive = _computeIsActive(start, end);

        if (!isManuallyInactive) {
          if (promo['is_active'] != shouldBeActive) {
            await _client
                .from('promotion')
                .update({'is_active': shouldBeActive})
                .eq('promotion_id', promo['promotion_id']);

            promo['is_active'] = shouldBeActive;
          }
        }
      }
      return promos;
    } catch (e) {
      return [];
    }
  }

  // ================= UPDATE PROMO =================
  static Future<String?> updatePromotion({
    required int adminId,
    required int promotionId,
    required String promotionName,
    required double minSpent,
    required String discountType,
    required double discountValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final old = await _client
          .from('promotion')
          .select()
          .eq('promotion_id', promotionId)
          .single();

      final bool isActive = _computeIsActive(startDate, endDate);
      final newData = {
        'promotion_name': promotionName.trim(),
        'min_spent': minSpent,
        'discount_type': discountType,
        'discount_value': discountValue,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate.toUtc().toIso8601String(),
        'is_active': isActive,
      };

      await _client
          .from('promotion')
          .update(newData)
          .eq('promotion_id', promotionId);

      await AuditService.log(
        adminId: adminId,
        action: 'promo.update',
        entityType: 'promotion',
        entityId: promotionId.toString(),
        oldValue: Map<String, dynamic>.from(old),
        newValue: newData,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= DELETE PROMO =================
  static Future<String?> deletePromotion(
      int promotionId, int adminId) async {
    try {
      final old = await _client
          .from('promotion')
          .select()
          .eq('promotion_id', promotionId)
          .single();

      await _client
          .from('promotion')
          .delete()
          .eq('promotion_id', promotionId);

      await AuditService.log(
        adminId:    adminId,
        action:     'promo.delete',
        entityType: 'promotion',
        entityId:   promotionId.toString(),
        oldValue:   Map<String, dynamic>.from(old),
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= DISCONTINUE PROMO =================
  static Future<String?> discontinuePromotion(int promotionId, int adminId) async {
    try {
      // Snapshot before updating
      final old = await _client
          .from('promotion')
          .select()
          .eq('promotion_id', promotionId)
          .single();

      await _client
          .from('promotion')
          .update({'is_active': false})
          .eq('promotion_id', promotionId);

      await AuditService.log(
        adminId:    adminId,
        action:     'promo.discontinue',
        entityType: 'promotion',
        entityId:   promotionId.toString(),
        oldValue:   Map<String, dynamic>.from(old),
        newValue:   {...Map<String, dynamic>.from(old), 'is_active': false},
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static bool _computeIsActive(DateTime start, DateTime end) {
    final DateTime now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }
}