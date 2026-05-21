import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscription plans for employers
enum SubscriptionPlan {
  free,    // 4 jobs per month - default - No code
  basic,   // 5 jobs per month - 5,000 VND - EMP-CB
  standard, // 6 jobs per month - 6,000 VND - EMP-T
  vip,     // 7 jobs per month - 7,000 VND - EMP-V
}

/// Extension to get plan codes
extension SubscriptionPlanExtension on SubscriptionPlan {
  String get code {
    switch (this) {
      case SubscriptionPlan.free:
        return 'FREE';
      case SubscriptionPlan.basic:
        return 'EMP-CB';
      case SubscriptionPlan.standard:
        return 'EMP-T';
      case SubscriptionPlan.vip:
        return 'EMP-V';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Miễn phí';
      case SubscriptionPlan.basic:
        return 'Cơ bản';
      case SubscriptionPlan.standard:
        return 'Thường';
      case SubscriptionPlan.vip:
        return 'VIP';
    }
  }
}

class SubscriptionInfo { // True if user had a paid plan that expired

  SubscriptionInfo({
    required this.plan,
    required this.maxJobsPerMonth,
    required this.price,
    this.expiresAt,
    this.usedJobsThisMonth = 0,
    this.wasExpired = false,
  });
  final SubscriptionPlan plan;
  final int maxJobsPerMonth;
  final int price;
  final DateTime? expiresAt;
  final int usedJobsThisMonth;
  final bool wasExpired;

  int get remainingJobs => maxJobsPerMonth - usedJobsThisMonth;
  bool get canPostJob => remainingJobs > 0;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  /// Days remaining until subscription expires
  int get daysRemaining {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
  
  /// Check if subscription is about to expire (within 7 days)
  bool get isAboutToExpire => daysRemaining > 0 && daysRemaining <= 7;

  static SubscriptionInfo fromPlan(SubscriptionPlan plan, {int usedJobs = 0, DateTime? expiresAt, bool wasExpired = false}) {
    switch (plan) {
      case SubscriptionPlan.free:
        return SubscriptionInfo(
          plan: plan,
          maxJobsPerMonth: 4,
          price: 0,
          usedJobsThisMonth: usedJobs,
          wasExpired: wasExpired,
        );
      case SubscriptionPlan.basic:
        return SubscriptionInfo(
          plan: plan,
          maxJobsPerMonth: 5,
          price: 5000,
          expiresAt: expiresAt,
          usedJobsThisMonth: usedJobs,
          wasExpired: wasExpired,
        );
      case SubscriptionPlan.standard:
        return SubscriptionInfo(
          plan: plan,
          maxJobsPerMonth: 6,
          price: 6000,
          expiresAt: expiresAt,
          usedJobsThisMonth: usedJobs,
          wasExpired: wasExpired,
        );
      case SubscriptionPlan.vip:
        return SubscriptionInfo(
          plan: plan,
          maxJobsPerMonth: 7,
          price: 7000,
          expiresAt: expiresAt,
          usedJobsThisMonth: usedJobs,
          wasExpired: wasExpired,
        );
    }
  }
}

class SubscriptionService {

  SubscriptionService() : _supabase = Supabase.instance.client;
  final SupabaseClient _supabase;

  /// Get current user's subscription info
  Future<SubscriptionInfo> getCurrentSubscription() async {
    final userId = _supabase.auth.currentUser?.id;
    debugPrint('📦 SubscriptionService: Getting subscription for user: $userId');
    
    if (userId == null) {
      debugPrint('📦 SubscriptionService: No user logged in, returning free plan');
      return SubscriptionInfo.fromPlan(SubscriptionPlan.free);
    }

    try {
      // Get profile with subscription metadata
      debugPrint('📦 SubscriptionService: Fetching profile metadata...');
      final response = await _supabase
          .from('profiles')
          .select('metadata')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('📦 SubscriptionService: Profile response: $response');

      if (response == null) {
        debugPrint('📦 SubscriptionService: No profile found, returning free plan');
        return SubscriptionInfo.fromPlan(SubscriptionPlan.free);
      }

      final metadata = response['metadata'] as Map<String, dynamic>? ?? {};
      final subscriptionData = metadata['subscription'] as Map<String, dynamic>?;

      if (subscriptionData == null) {
        // Count jobs posted this month for free tier
        final usedJobs = await _countJobsThisMonth(userId);
        return SubscriptionInfo.fromPlan(SubscriptionPlan.free, usedJobs: usedJobs);
      }

      final planStr = subscriptionData['plan'] as String? ?? 'free';
      final expiresAtStr = subscriptionData['expires_at'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : null;

      // Check if subscription expired - reset to free plan
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        debugPrint('📦 SubscriptionService: Subscription expired, resetting to free plan');
        final usedJobs = await _countJobsThisMonth(userId);
        
        // Return free plan with wasExpired flag so UI can show "Gia hạn" option
        return SubscriptionInfo.fromPlan(
          SubscriptionPlan.free, 
          usedJobs: usedJobs,
          wasExpired: true, // Mark that user previously had a paid plan
        );
      }

      final plan = _parsePlan(planStr);
      final usedJobs = await _countJobsThisMonth(userId);
      debugPrint('📦 SubscriptionService: Plan: $plan, Used jobs: $usedJobs');

      return SubscriptionInfo.fromPlan(plan, usedJobs: usedJobs, expiresAt: expiresAt);
    } catch (e, stackTrace) {
      debugPrint('❌ SubscriptionService Error: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      return SubscriptionInfo.fromPlan(SubscriptionPlan.free);
    }
  }

  /// Count jobs created by user this month
  Future<int> _countJobsThisMonth(String userId) async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      // Count regular jobs
      final regularJobs = await _supabase
          .from('jobs')
          .select('id')
          .eq('creator_id', userId)
          .gte('created_at', firstDayOfMonth.toIso8601String());
      
      // Count partnership jobs
      final partnershipJobs = await _supabase
          .from('school_partnership_jobs')
          .select('id')
          .eq('company_id', userId)
          .gte('created_at', firstDayOfMonth.toIso8601String());

      return (regularJobs as List).length + (partnershipJobs as List).length;
    } catch (e) {
      debugPrint('Error counting jobs: $e');
      return 0;
    }
  }

  /// Check if user can post a new job
  Future<bool> canPostJob() async {
    final subscription = await getCurrentSubscription();
    return subscription.canPostJob && !subscription.isExpired;
  }

  /// Save subscription after successful payment
  Future<void> saveSubscription(SubscriptionPlan plan, String transactionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final expiresAt = DateTime(now.year, now.month + 1, now.day); // 1 month subscription

    // Get current metadata
    final response = await _supabase
        .from('profiles')
        .select('metadata')
        .eq('id', userId)
        .single();

    final metadata = Map<String, dynamic>.from(response['metadata'] ?? {});
    
    // Get plan price
    final planInfo = SubscriptionInfo.fromPlan(plan);
    
    // Update subscription in metadata
    metadata['subscription'] = {
      'plan': plan.name,
      'started_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'transaction_id': transactionId,
    };

    // Add to payment history
    final paymentHistory = List<Map<String, dynamic>>.from(metadata['payment_history'] ?? []);
    paymentHistory.add({
      'transaction_id': transactionId,
      'plan_code': plan.code,
      'amount': planInfo.price,
      'date': now.toIso8601String(),
    });
    metadata['payment_history'] = paymentHistory;

    // Save to database
    await _supabase
        .from('profiles')
        .update({'metadata': metadata})
        .eq('id', userId);
  }

  SubscriptionPlan _parsePlan(String planStr) {
    switch (planStr.toLowerCase()) {
      case 'basic':
        return SubscriptionPlan.basic;
      case 'standard':
        return SubscriptionPlan.standard;
      case 'vip':
        return SubscriptionPlan.vip;
      default:
        return SubscriptionPlan.free;
    }
  }

  String getPlanDisplayName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Miễn phí';
      case SubscriptionPlan.basic:
        return 'Cơ bản';
      case SubscriptionPlan.standard:
        return 'Thường';
      case SubscriptionPlan.vip:
        return 'VIP';
    }
  }
}
