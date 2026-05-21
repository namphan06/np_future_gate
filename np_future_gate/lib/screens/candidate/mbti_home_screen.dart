import 'package:flutter/material.dart';

import 'package:np_future_gate/core/models/mbti_model.dart';
import 'package:np_future_gate/core/repositories/mbti_repository.dart';
import 'package:np_future_gate/core/theme/app_main_colors.dart';
import 'package:np_future_gate/screens/candidate/mbti_type_detail_screen.dart';

class MBTIHomeScreen extends StatefulWidget {

  const MBTIHomeScreen({super.key, this.selectedCode});
  final String? selectedCode;

  @override
  State<MBTIHomeScreen> createState() => _MBTIHomeScreenState();
}

class _MBTIHomeScreenState extends State<MBTIHomeScreen> {
  final MBTIRepository _repository = MBTIRepository();
  bool _isLoading = true;
  List<MBTIType> _types = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final types = await _repository.getActiveTypes();
    if (!mounted) {
      return;
    }

    setState(() {
      _types = types;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trang chủ MBTI',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppMainColors.primary),
            )
          : _types.isEmpty
          ? const Center(child: Text('Chưa có dữ liệu MBTI.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    '16 nhóm tính cách MBTI',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppMainColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.22,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _types.length,
                    itemBuilder: (context, index) {
                      final type = _types[index];
                      final isSelected =
                          widget.selectedCode?.toUpperCase() ==
                          type.code.toUpperCase();

                      return _MBTITypeCard(
                        type: type,
                        isSelected: isSelected,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MBTITypeDetailScreen(
                                type: type,
                                allTypes: _types,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _MBTITypeCard extends StatelessWidget {

  const _MBTITypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });
  final MBTIType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = _parseColor(type.colorHex) ?? const Color(0xFFEAF7EE);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppMainColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                      child: type.imageUrl == null || type.imageUrl!.isEmpty
                          ? Container(color: Colors.white24)
                          : Image.network(
                              type.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.white24),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.code,
                            style: const TextStyle(
                              fontSize: 30,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF004D40),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.name ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF004D40),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isSelected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppMainColors.primary,
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return null;
    }
    final normalized = colorHex.replaceAll('#', '');
    if (normalized.length == 6) {
      return Color(int.parse('FF$normalized', radix: 16));
    }
    if (normalized.length == 8) {
      return Color(int.parse(normalized, radix: 16));
    }
    return null;
  }
}
