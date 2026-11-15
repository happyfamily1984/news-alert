import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme.dart';

/// 화면 ② 키워드 추가.
/// Enter 키로도 등록, 중복 등록 방지, 공백만 입력 시 등록 차단,
/// 등록 완료 시 홈으로 이동 + 성공 메시지.
class AddKeywordScreen extends StatefulWidget {
  const AddKeywordScreen({super.key});

  @override
  State<AddKeywordScreen> createState() => _AddKeywordScreenState();
}

class _AddKeywordScreenState extends State<AddKeywordScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      setState(() => _error = '키워드를 입력해 주세요.');
      return;
    }
    final existing = await StorageService.instance.getKeywords();
    if (existing.any((k) => k.toLowerCase() == keyword.toLowerCase())) {
      setState(() => _error = '이미 등록된 키워드입니다.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await StorageService.instance.addKeyword(keyword);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '키워드 추가',
          style: AppTextStyles.screenTitle(brightness),
        ),
      ),
      // SingleChildScrollView + SafeArea: 작은 화면이나 키보드가 올라와도
      // 하단 안내 문구가 잘리지 않는다.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관심 있는 뉴스 키워드를 등록해 보세요.',
                      style: AppTextStyles.body(
                        brightness,
                      ).copyWith(
                        fontSize: 16,
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onChanged: (_) {
                        if (_error != null) {
                          setState(() => _error = null);
                        }
                      },
                      style: AppTextStyles.body(
                        brightness,
                      ).copyWith(fontSize: 16),
                      decoration: InputDecoration(
                          hintText: '예) 인공지능, 부동산, 전기차',
                          hintStyle: AppTextStyles.body(
                            brightness,
                          ).copyWith(
                            fontSize: 16,
                            color: AppColors.textSecondary(brightness),
                          ),
                          errorText: _error,
                          filled: true,
                          fillColor: AppColors.inputFill(brightness),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.inputBorder(brightness),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.inputBorder(brightness),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.primary(brightness),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: AppSizes.buttonHeight,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(brightness),
                          foregroundColor: AppColors.onPrimary(brightness),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          '등록하기',
                          style: AppTextStyles.button(brightness),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        '연합뉴스 RSS에서 해당 키워드가 포함된 뉴스를 확인합니다.',
                        style: AppTextStyles.meta(
                          brightness,
                        ).copyWith(fontSize: 12, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
