import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:np_future_gate/core/services/subscription_service.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  bool _isLoading = true;
  List<PaymentTransaction> _transactions = [];
  SubscriptionInfo? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current subscription info
      final subscription = await _subscriptionService.getCurrentSubscription();
      
      // Get payment history from profile metadata
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        final response = await _supabaseService.client
            .from('profiles')
            .select('metadata')
            .eq('id', userId)
            .single();
        
        final metadata = response['metadata'] as Map<String, dynamic>?;
        final paymentHistory = metadata?['payment_history'] as List<dynamic>?;
        
        if (paymentHistory != null) {
          _transactions = paymentHistory
              .map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>))
              .toList();
          // Sort by date descending (newest first)
          _transactions.sort((a, b) => b.date.compareTo(a.date));
        }
      }
      
      setState(() {
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Custom AppBar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple,
                  Colors.purple.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Lịch sử thanh toán',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Xem tất cả giao dịch của bạn',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPaymentHistory,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Current subscription summary
                            if (_currentSubscription != null) ...[
                              _buildCurrentSubscriptionCard(),
                              const SizedBox(height: 24),
                            ],
                            
                            // Statistics
                            _buildStatisticsCard(),
                            const SizedBox(height: 24),
                            
                            // Transaction list header
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12),
                              child: Row(
                                children: [
                                  Text(
                                    'Giao dịch gần đây',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_transactions.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Transaction items
                            ..._transactions.map((transaction) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTransactionCard(transaction),
                            )),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: Colors.purple.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nâng cấp tài khoản để bắt đầu sử dụng\ncác tính năng cao cấp',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final sub = _currentSubscription!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sub.plan == SubscriptionPlan.free
              ? [Colors.grey, Colors.grey.shade600]
              : [AppMainColors.primary, AppMainColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (sub.plan == SubscriptionPlan.free ? Colors.grey : AppMainColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gói hiện tại',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sub.plan.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('${sub.usedJobsThisMonth}/${sub.maxJobsPerMonth}', 'Tin đã đăng'),
              Container(height: 40, width: 1, color: Colors.white24),
              _buildStatItem('${sub.remainingJobs}', 'Tin còn lại'),
              if (sub.expiresAt != null && !sub.isExpired) ...[
                Container(height: 40, width: 1, color: Colors.white24),
                _buildStatItem('${sub.daysRemaining}', 'Ngày còn lại'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final totalAmount = _transactions.fold<int>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    
    final totalTransactions = _transactions.length;
    final lastPayment = _transactions.isNotEmpty ? _transactions.first.date : null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.payments_rounded,
                  label: 'Tổng chi tiêu',
                  value: _formatCurrency(totalAmount),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.receipt_rounded,
                  label: 'Giao dịch',
                  value: '$totalTransactions',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          if (lastPayment != null) ...[
            const SizedBox(height: 12),
            _buildStatBox(
              icon: Icons.access_time_rounded,
              label: 'Thanh toán gần nhất',
              value: DateFormat('dd/MM/yyyy HH:mm').format(lastPayment),
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    final planInfo = _getPlanInfo(transaction.planCode);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetail(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: planInfo.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(planInfo.icon, color: planInfo.color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planInfo.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(transaction.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: planInfo.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Thành công',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Order code
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Mã GD: ${transaction.transactionId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(PaymentTransaction transaction) {
    final planInfo = _getPlanInfo(transaction.planCode);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: planInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(planInfo.icon, color: planInfo.color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết giao dịch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          planInfo.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Details
              _buildDetailRow('Gói dịch vụ', planInfo.name),
              _buildDetailRow('Số tiền', '${_formatCurrency(transaction.amount)} VNĐ'),
              _buildDetailRow('Mã giao dịch', transaction.transactionId),
              _buildDetailRow('Thời gian', DateFormat('dd/MM/yyyy HH:mm:ss').format(transaction.date)),
              _buildDetailRow('Trạng thái', 'Thành công', valueColor: Colors.green),
              
              const SizedBox(height: 20),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: planInfo.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PlanInfo _getPlanInfo(String planCode) {
    switch (planCode) {
      case 'EMP-CB':
        return PlanInfo(
          name: 'Gói Cơ bản',
          icon: Icons.verified,
          color: Colors.blue,
        );
      case 'EMP-T':
        return PlanInfo(
          name: 'Gói Thường',
          icon: Icons.star,
          color: Colors.green,
        );
      case 'EMP-V':
        return PlanInfo(
          name: 'Gói VIP',
          icon: Icons.diamond,
          color: Colors.amber[700]!,
        );
      default:
        return PlanInfo(
          name: 'Gói Miễn phí',
          icon: Icons.person,
          color: Colors.grey,
        );
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class PaymentTransaction {

  PaymentTransaction({
    required this.transactionId,
    required this.planCode,
    required this.amount,
    required this.date,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      transactionId: json['transaction_id'] ?? '',
      planCode: json['plan_code'] ?? '',
      amount: json['amount'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }
  final String transactionId;
  final String planCode;
  final int amount;
  final DateTime date;

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'plan_code': planCode,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}

class PlanInfo {

  PlanInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
  final String name;
  final IconData icon;
  final Color color;
}
