import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/payos_service.dart';
import '../../../core/theme/app_main_colors.dart';

class UpgradeAccountScreen extends StatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  State<UpgradeAccountScreen> createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PayOSService _payOSService = PayOSService();
  
  SubscriptionInfo? _currentSubscription;
  bool _isLoading = true;
  SubscriptionPlan? _selectedPlan;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      setState(() {
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: $e')),
        );
      }
    }
  }

  Future<void> _processPayment(SubscriptionPlan plan) async {
    if (_isProcessingPayment) return;
    
    setState(() {
      _selectedPlan = plan;
      _isProcessingPayment = true;
    });

    try {
      final planInfo = SubscriptionInfo.fromPlan(plan);
      final userId = _subscriptionService.toString(); // Get actual user ID
      
      final result = await _payOSService.createPaymentLink(
        amount: planInfo.price,
        planName: plan.code, // Use plan code: EMP-CB, EMP-T, EMP-V
        userId: userId,
      );

      if (result.success && result.qrCodeData != null) {
        // Show QR code dialog directly in app
        if (mounted) {
          _showQRPaymentDialog(result);
        }
      } else if (result.success && result.paymentUrl != null) {
        // Fallback to payment URL if QR not available
        if (mounted) {
          _showQRPaymentDialog(result);
        }
      } else {
        throw Exception(result.error ?? 'Lỗi tạo link thanh toán');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  void _showQRPaymentDialog(PaymentResult paymentResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppMainColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.qr_code_2, color: AppMainColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quét mã QR để thanh toán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mã gói: ${_selectedPlan?.code ?? ''}',
                          style: TextStyle(
                            fontSize: 13,
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

              // QR Code - Using qr_flutter to render QR from data string
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: paymentResult.qrCodeData != null
                    ? QrImageView(
                        data: paymentResult.qrCodeData!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('QR không khả dụng'),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Payment info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildPaymentInfoRow('Số tiền:', '${_formatCurrency(paymentResult.amount ?? 0)} VNĐ'),
                    const Divider(height: 12),
                    _buildPaymentInfoRow('Mã đơn hàng:', paymentResult.orderCode ?? ''),
                    if (paymentResult.accountNumber != null) ...[
                      const Divider(height: 12),
                      _buildPaymentInfoRow('Số TK:', paymentResult.accountNumber!),
                    ],
                    if (paymentResult.accountName != null) ...[
                      const Divider(height: 12),
                      _buildPaymentInfoRow('Chủ TK:', paymentResult.accountName!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mở app ngân hàng, quét mã QR và thanh toán.\nSau khi thanh toán xong, nhấn "Xác nhận".',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _verifyPayment(paymentResult.orderCode!);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Đã thanh toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppMainColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _verifyPayment(String orderCode) async {
    setState(() => _isProcessingPayment = true);

    try {
      final status = await _payOSService.checkPaymentStatus(orderCode);

      if (status.isPaid) {
        // Save subscription
        await _subscriptionService.saveSubscription(
          _selectedPlan!,
          status.transactionId ?? orderCode,
        );

        // Reload subscription info
        await _loadSubscription();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Kích hoạt gói thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chưa nhận được thanh toán. Trạng thái: ${status.status}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác nhận: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Custom AppBar with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppMainColors.primary,
                        AppMainColors.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppMainColors.primary.withOpacity(0.3),
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
                          // Back button with custom design
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
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
                          // Title with icon
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Nâng cấp tài khoản',
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
                                  'Chọn gói phù hợp với nhu cầu của bạn',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Current subscription info
                  _buildCurrentSubscriptionCard(),
                        const SizedBox(height: 24),

                        // Plans header
                        const Text(
                    'Chọn gói phù hợp',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nâng cấp để đăng thêm tin tuyển dụng mỗi tháng',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Plan cards
                        _buildPlanCard(
                    plan: SubscriptionPlan.free,
                    title: 'Miễn phí',
                    price: 'Miễn phí',
                    maxJobs: 4,
                    features: [
                      'Đăng tối đa 4 tin/tháng',
                      'Quản lý ứng viên cơ bản',
                      'Xem CV ứng viên',
                    ],
                          color: Colors.grey,
                          isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.free,
                        ),
                        const SizedBox(height: 16),

                        _buildPlanCard(
                    plan: SubscriptionPlan.basic,
                    title: 'Cơ bản',
                    price: '5.000 VNĐ/tháng',
                    maxJobs: 5,
                    features: [
                      'Đăng tối đa 5 tin/tháng',
                      'Quản lý ứng viên cơ bản',
                      'Xem CV ứng viên',
                      'Hỗ trợ email',
                    ],
                          color: Colors.blue,
                          isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.basic,
                        ),
                        const SizedBox(height: 16),

                        _buildPlanCard(
                    plan: SubscriptionPlan.standard,
                    title: 'Thường',
                    price: '6.000 VNĐ/tháng',
                    maxJobs: 6,
                    features: [
                      'Đăng tối đa 6 tin/tháng',
                      'Quản lý ứng viên nâng cao',
                      'Xem CV ứng viên',
                      'Thống kê chi tiết',
                      'Hỗ trợ ưu tiên',
                    ],
                          color: Colors.green,
                          isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.standard,
                          isPopular: true,
                        ),
                        const SizedBox(height: 16),

                        _buildPlanCard(
                    plan: SubscriptionPlan.vip,
                    title: 'VIP',
                    price: '7.000 VNĐ/tháng',
                    maxJobs: 7,
                    features: [
                      'Đăng tối đa 7 tin/tháng',
                      'Quản lý ứng viên cao cấp',
                      'Xem CV ứng viên',
                      'Thống kê chi tiết',
                      'Tin được ưu tiên hiển thị',
                      'Hỗ trợ 24/7',
                    ],
                          color: Colors.amber[700]!,
                          isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.vip,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    if (_currentSubscription == null) return const SizedBox.shrink();

    final sub = _currentSubscription!;
    
    // Show expired notice if subscription was expired
    if (sub.wasExpired) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[600]!, Colors.orange[400]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Gói đăng ký đã hết hạn!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bạn đang sử dụng gói miễn phí. Gia hạn để tiếp tục sử dụng các tính năng cao cấp.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${sub.usedJobsThisMonth}/${sub.maxJobsPerMonth}',
                  'Tin đã đăng',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildStatItem(
                  '${sub.remainingJobs}',
                  'Tin còn lại',
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppMainColors.primary, AppMainColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppMainColors.primary.withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.2),
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
          // Warning if about to expire
          if (sub.isAboutToExpire)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.yellow, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Gói sẽ hết hạn trong ${sub.daysRemaining} ngày. Gia hạn ngay!',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${sub.usedJobsThisMonth}/${sub.maxJobsPerMonth}',
                'Tin đã đăng',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              _buildStatItem(
                '${sub.remainingJobs}',
                'Tin còn lại',
              ),
              if (sub.expiresAt != null && !sub.isExpired) ...[
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildStatItem(
                  '${sub.daysRemaining}',
                  'Ngày còn lại',
                ),
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

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String title,
    required String price,
    required int maxJobs,
    required List<String> features,
    required Color color,
    bool isCurrentPlan = false,
    bool isPopular = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentPlan ? color : Colors.grey.shade200,
              width: isCurrentPlan ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      plan == SubscriptionPlan.vip
                          ? Icons.diamond
                          : plan == SubscriptionPlan.standard
                              ? Icons.star
                              : plan == SubscriptionPlan.basic
                                  ? Icons.verified
                                  : Icons.person,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Đang dùng',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Features
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              if (!isCurrentPlan && plan != SubscriptionPlan.free) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment
                        ? null
                        : () => _processPayment(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessingPayment && _selectedPlan == plan
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Nâng cấp ngay',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Popular badge
        if (isPopular)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🔥 Phổ biến',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
