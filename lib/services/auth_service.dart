import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Simple enums for status
enum AccessStatus {
  pending,
  approved,
  rejected,
  unknown
}

class AuthService {
  // Create a new request
  Future<String> requestAccess(String userName) async {
    final deviceName = Platform.operatingSystem; // Simple device info
    
    // Insert into 'access_requests' table
    final response = await Supabase.instance.client
        .from('access_requests')
        .insert({
          'user_name': userName,
          'device_name': deviceName,
          'status': 'pending',
          // Timestamp is handled by default in Supabase if column is timestamptz
        })
        .select()
        .single();

    final requestId = response['id'].toString();

    // Save ID locally to track status later
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('request_id', requestId);
    
    return requestId;
  }

  // Get current Request ID if exists
  Future<String?> getPendingRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('request_id');
  }

  // Listen to status changes real-time
  Stream<AccessStatus> statusStream(String requestId) {
    if (requestId.isEmpty) return Stream.value(AccessStatus.unknown);
    
    return Supabase.instance.client
        .from('access_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((List<Map<String, dynamic>> data) {
          if (data.isEmpty) return AccessStatus.unknown;
          
          final status = data.first['status'] as String?;
          
          if (status == 'approved') return AccessStatus.approved;
          if (status == 'rejected') return AccessStatus.rejected;
          return AccessStatus.pending;
        });
  }

  // Check status once (for app startup)
  Future<AccessStatus> checkStatus() async {
    final requestId = await getPendingRequestId();
    if (requestId == null) return AccessStatus.unknown;

    try {
      final response = await Supabase.instance.client
          .from('access_requests')
          .select('status')
          .eq('id', requestId)
          .maybeSingle();

      if (response == null) return AccessStatus.unknown;

      final status = response['status'] as String?;
      if (status == 'approved') return AccessStatus.approved;
      if (status == 'rejected') return AccessStatus.rejected;
      return AccessStatus.pending;
    } catch (e) {
      // Offline or error
      return AccessStatus.unknown;
    }
  }

  // Finalize activation locally
  Future<void> activateApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', true);
  }

  Future<bool> isAppActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_activated') ?? false;
  }
}
