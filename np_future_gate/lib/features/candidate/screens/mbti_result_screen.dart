import 'package:flutter/material.dart';

import 'package:np_future_gate/core/models/mbti_model.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/features/candidate/screens/mbti_home_screen.dart';
import 'package:np_future_gate/features/candidate/screens/mbti_type_detail_screen.dart';

class MBTIResultScreen extends StatelessWidget {

  const MBTIResultScreen({
    super.key,
    required this.resultType,
    this.allTypes = const [],
    this.reasoning,
  });
  final MBTIType resultType;
  final List<MBTIType> allTypes;
  final String? reasoning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chúc mừng bạn đã hoàn thành bài test!',
                          style: TextStyle(
                            fontSize: 30,
                            color: AppMainColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child:
                              resultType.imageUrl == null ||
                                  resultType.imageUrl!.isEmpty
                              ? Container(
                                  color: const Color(0xFFE8F5E9),
                                  alignment: Alignment.center,
                                  child: Text(
                                    resultType.code,
                                    style: const TextStyle(
                                      fontSize: 42,
                                      color: AppMainColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Image.network(
                                  resultType.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE8F5E9),
                                    alignment: Alignment.center,
                                    child: Text(
                                      resultType.code,
                                      style: const TextStyle(
                                        fontSize: 42,
                                        color: AppMainColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bạn thuộc nhóm tính cách',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFF25324A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${resultType.code} - ${resultType.name ?? ''}',
                              style: const TextStyle(
                                fontSize: 44,
                                height: 1,
                                color: AppMainColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              reasoning ?? resultType.shortDescription ?? '',
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.6,
                                color: Color(0xFF344054),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MBTITypeDetailScreen(
                              type: resultType,
                              allTypes: allTypes,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EDF3),
                        foregroundColor: const Color(0xFF2A3546),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MBTIHomeScreen(selectedCode: resultType.code),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppMainColors.primary,
                      ),
                      label: const Text(
                        'Về trang chủ MBTI',
                        style: TextStyle(
                          color: AppMainColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
