import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/features/guest/data/model/guest_group_model.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_group_notifier.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_notifier.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_summary_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수 (기존 앱 테마와 동일)
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF1A1A19);
const _kBg2 = Color(0xFF111110);
const _kCardBg = Color(0x1AFFFFFF);
const _kBorder = Color(0x33FFFFFF);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kPink = Color(0xFFEC4899);

// ---------------------------------------------------------------------------
// GuestFormScreen
// ---------------------------------------------------------------------------

/// 하객 추가/수정 폼 화면.
///
/// [guestOid] null이면 추가 모드, 값이 있으면 수정 모드.
class GuestFormScreen extends ConsumerStatefulWidget {
  final String? guestOid;

  const GuestFormScreen({super.key, this.guestOid});

  @override
  ConsumerState<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends ConsumerState<GuestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final _nameCtrl = TextEditingController();
  final _companionCtrl = TextEditingController(text: '0');
  final _giftCtrl = TextEditingController(text: '0');
  final _memoCtrl = TextEditingController();

  // 선택 값
  String? _selectedGroupOid;
  String _invitationStatus = 'NONE';
  String _attendStatus = 'UNDECIDED';

  bool _isLoading = false;
  bool get _isEdit => widget.guestOid != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGroups();
      if (_isEdit) _prefillForm();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companionCtrl.dispose();
    _giftCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _initGroups() {
    final groupState = ref.read(guestGroupNotifierProvider);
    if (groupState is GuestGroupInitial) {
      ref.read(guestGroupNotifierProvider.notifier).loadGroups();
    }
  }

  void _prefillForm() {
    if (!_isEdit) return;
    final guestState = ref.read(guestNotifierProvider);
    if (guestState is! GuestLoaded) return;

    final guest = guestState.guests
        .where((g) => g.oid == widget.guestOid)
        .firstOrNull;
    if (guest == null) return;

    _nameCtrl.text = guest.name;
    _companionCtrl.text = guest.companionCount.toString();
    _giftCtrl.text = guest.giftAmount.toString();
    _memoCtrl.text = guest.memo ?? '';
    setState(() {
      _selectedGroupOid = guest.groupOid;
      _invitationStatus = guest.invitationStatus;
      _attendStatus = guest.attendStatus;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'companionCount': int.tryParse(_companionCtrl.text) ?? 0,
      'giftAmount': int.tryParse(_giftCtrl.text) ?? 0,
      'invitationStatus': _invitationStatus,
      'attendStatus': _attendStatus,
    };

    // 그룹 처리: 선택 없으면 clearGroup=true로 그룹 해제 (수정 모드), 추가 모드는 null
    if (_selectedGroupOid != null) {
      body['groupOid'] = _selectedGroupOid;
    } else if (_isEdit) {
      body['clearGroup'] = true;
    }

    final memo = _memoCtrl.text.trim();
    if (memo.isNotEmpty) {
      body['memo'] = memo;
    }

    bool success;
    if (_isEdit) {
      success = await ref
          .read(guestNotifierProvider.notifier)
          .updateGuest(widget.guestOid!, body);
    } else {
      success = await ref
          .read(guestNotifierProvider.notifier)
          .createGuest(body);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // 요약 데이터 갱신
      ref.invalidate(guestSummaryProvider);
      Navigator.of(context).pop(true);
    } else {
      final guestState = ref.read(guestNotifierProvider);
      if (guestState is GuestError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(guestState.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _kText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? '하객 수정' : '하객 추가',
          style: const TextStyle(
            color: _kText,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kPink,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      color: _kPink,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _buildSection('기본 정보', [
                _buildTextField(
                  controller: _nameCtrl,
                  label: '이름',
                  hint: '홍길동',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '이름을 입력하세요.';
                    if (v.trim().length > 50) return '50자 이내로 입력하세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildGroupDropdown(),
              ]),
              const SizedBox(height: 16),
              _buildSection('참석 정보', [
                _buildStatusRow(
                  label: '참석 여부',
                  value: _attendStatus,
                  options: const [
                    ('ATTEND', '참석'),
                    ('ABSENT', '불참'),
                    ('UNDECIDED', '미정'),
                  ],
                  onChanged: (v) => setState(() => _attendStatus = v),
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  label: '청첩장',
                  value: _invitationStatus,
                  options: const [
                    ('NONE', '미전달'),
                    ('PAPER', '종이'),
                    ('MOBILE', '모바일'),
                  ],
                  onChanged: (v) => setState(() => _invitationStatus = v),
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _companionCtrl,
                  label: '동반 인원',
                  hint: '0',
                  suffix: '명',
                  maxVal: 99,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('축의금 / 메모', [
                _buildNumberField(
                  controller: _giftCtrl,
                  label: '축의금',
                  hint: '0',
                  suffix: '원',
                  maxVal: 9999999,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _memoCtrl,
                  label: '메모',
                  hint: '팀장님, 가족 친구 등 (선택)',
                  maxLines: 3,
                  validator: (v) {
                    if (v != null && v.length > 500) return '500자 이내로 입력하세요.';
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── 섹션 레이아웃 ──────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _kTextSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // ── 입력 필드 ──────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPink),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      ),
      validator: validator,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required int maxVal,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _kTextSub),
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPink),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      ),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null) return '숫자를 입력하세요.';
        if (n < 0) return '0 이상이어야 합니다.';
        if (n > maxVal) return '$maxVal 이하여야 합니다.';
        return null;
      },
    );
  }

  // ── 그룹 드롭다운 ─────────────────────────────────────────────────────────

  Widget _buildGroupDropdown() {
    final groupState = ref.watch(guestGroupNotifierProvider);
    List<GuestGroupModel> groups = [];
    if (groupState is GuestGroupLoaded) {
      groups = groupState.groups;
    }

    return DropdownButtonFormField<String?>(
      value: _selectedGroupOid,
      dropdownColor: const Color(0xFF1E1B3A),
      style: const TextStyle(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        labelText: '그룹',
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 13),
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPink),
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('없음 (미분류)', style: TextStyle(color: _kTextSub)),
        ),
        ...groups.map(
          (g) => DropdownMenuItem<String?>(
            value: g.oid,
            child: Text(g.name),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _selectedGroupOid = v),
    );
  }

  // ── 상태 선택 행 ──────────────────────────────────────────────────────────

  Widget _buildStatusRow({
    required String label,
    required String value,
    required List<(String, String)> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _kTextSub, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final (optValue, optLabel) = opt;
            final isSelected = value == optValue;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(optValue),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPink.withOpacity(0.2)
                        : const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _kPink : _kBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    optLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? _kPink : _kTextSub,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
