import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:weddy/features/vendor/data/model/vendor_model.dart';
import 'package:weddy/features/vendor/presentation/notifier/vendor_detail_notifier.dart';
import 'package:weddy/features/vendor/presentation/notifier/vendor_notifier.dart';

// ---------------------------------------------------------------------------
// 색상 상수
// ---------------------------------------------------------------------------

const _kBg1 = Color(0xFF080810);
const _kBg2 = Color(0xFF0C0820);
const _kGlass = Color(0x1AFFFFFF);
const _kGlassBorder = Color(0x33FFFFFF);
const _kPink = Color(0xFFEC4899);
const _kText = Colors.white;
const _kTextSub = Color(0xAAFFFFFF);
const _kTextMute = Color(0x66FFFFFF);

// ---------------------------------------------------------------------------
// VendorDetailScreen
// ---------------------------------------------------------------------------

class VendorDetailScreen extends ConsumerWidget {
  final String vendorOid;

  const VendorDetailScreen({super.key, required this.vendorOid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(vendorDetailNotifierProvider(vendorOid));

    return Scaffold(
      backgroundColor: _kBg1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: switch (detailState) {
          VendorDetailInitial() || VendorDetailLoading() =>
            const Center(child: CircularProgressIndicator(color: _kPink)),
          VendorDetailError(:final message) => _buildError(context, message),
          VendorDetailLoaded(:final vendor) =>
            _buildContent(context, ref, vendor),
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: _kText, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: _kPink, size: 40),
                  const SizedBox(height: 12),
                  Text(message,
                      style: const TextStyle(
                          color: _kTextSub, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, VendorModel vendor) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, ref, vendor),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 배지 + 업체명
                Row(
                  children: [
                    _CategoryBadge(label: vendor.categoryLabel),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vendor.name,
                        style: GoogleFonts.notoSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 정보 카드
                _buildInfoCard(vendor),
                // 설명
                if (vendor.description != null &&
                    vendor.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDescriptionCard(vendor.description!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, WidgetRef ref, VendorModel vendor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _kBg1,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: _kText, size: 20),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _kPink.withOpacity(0.3),
                _kBg1,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              IconData(
                vendor.categoryIconCodePoint,
                fontFamily: 'MaterialIcons',
              ),
              size: 72,
              color: _kPink.withOpacity(0.6),
            ),
          ),
        ),
      ),
      actions: [
        // 즐겨찾기 FAB 역할을 앱바 액션으로 배치
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                vendor.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(vendor.isFavorite),
                color: vendor.isFavorite ? _kPink : _kTextSub,
                size: 26,
              ),
            ),
            onPressed: () async {
              await ref
                  .read(vendorDetailNotifierProvider(vendorOid).notifier)
                  .toggleFavorite();

              // API 재호출 없이 목록 상태만 로컬 동기화 (이중 호출 방지)
              final updated = ref.read(vendorDetailNotifierProvider(vendorOid));
              if (updated is VendorDetailLoaded) {
                ref
                    .read(vendorNotifierProvider.notifier)
                    .updateFavoriteStatus(
                      vendorOid,
                      updated.vendor.isFavorite,
                      updated.vendor.favoriteOid,
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(VendorModel vendor) {
    final items = <(IconData, String, String?)>[
      if (vendor.address != null && vendor.address!.isNotEmpty)
        (Icons.location_on_outlined, '주소', vendor.address),
      if (vendor.phone != null && vendor.phone!.isNotEmpty)
        (Icons.phone_outlined, '전화번호', vendor.phone),
      if (vendor.homepageUrl != null && vendor.homepageUrl!.isNotEmpty)
        (Icons.language_outlined, '홈페이지', vendor.homepageUrl),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final (icon, label, value) = entry.value;
              return Column(
                children: [
                  _InfoRow(
                    icon: icon,
                    label: label,
                    value: value!,
                    isLink: label == '홈페이지' || label == '전화번호',
                    onTap: () async {
                      if (label == '홈페이지') {
                        final uri = Uri.tryParse(value);
                        if (uri != null &&
                            (uri.scheme == 'http' || uri.scheme == 'https') &&
                            await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      } else if (label == '전화번호') {
                        final uri = Uri.parse('tel:$value');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    },
                  ),
                  if (i < items.length - 1)
                    Divider(
                        height: 16,
                        color: _kGlassBorder.withOpacity(0.5)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '업체 소개',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextSub,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 보조 위젯
// ---------------------------------------------------------------------------

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kPink.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPink.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kPink,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLink ? onTap : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kPink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: _kTextMute),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isLink ? _kPink : _kText,
                    decoration:
                        isLink ? TextDecoration.underline : null,
                    decorationColor: isLink ? _kPink : null,
                  ),
                ),
              ],
            ),
          ),
          if (isLink)
            const Icon(Icons.open_in_new, size: 14, color: _kTextMute),
        ],
      ),
    );
  }
}
