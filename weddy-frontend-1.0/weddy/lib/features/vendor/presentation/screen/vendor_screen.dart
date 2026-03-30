import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:weddy/features/vendor/data/model/vendor_model.dart';
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
// 카테고리 목록
// ---------------------------------------------------------------------------

const _kCategories = <(String?, String)>[
  (null, '전체'),
  ('HALL', '예식장'),
  ('STUDIO', '스튜디오'),
  ('DRESS', '드레스'),
  ('MAKEUP', '메이크업'),
  ('HONEYMOON', '허니문'),
  ('ETC', '기타'),
];

// ---------------------------------------------------------------------------
// VendorScreen
// ---------------------------------------------------------------------------

class VendorScreen extends ConsumerStatefulWidget {
  const VendorScreen({super.key});

  @override
  ConsumerState<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends ConsumerState<VendorScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 초기 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(vendorNotifierProvider);
      if (state is VendorInitial) {
        ref.read(vendorNotifierProvider.notifier).loadVendors();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _kBg1,
      appBar: _buildAppBar(vendorState),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              _buildCategoryFilter(vendorState),
              Expanded(child: _buildVendorList(vendorState)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(VendorState vendorState) {
    final isShowingFavorites =
        vendorState is VendorLoaded && vendorState.showingFavorites;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: _kText, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        '업체 찾기',
        style: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kText,
        ),
      ),
      actions: [
        IconButton(
          tooltip: isShowingFavorites ? '전체 목록' : '즐겨찾기',
          icon: Icon(
            isShowingFavorites ? Icons.favorite : Icons.favorite_border,
            color: isShowingFavorites ? _kPink : _kTextSub,
            size: 22,
          ),
          onPressed: () {
            final notifier = ref.read(vendorNotifierProvider.notifier);
            if (isShowingFavorites) {
              _searchController.clear();
              notifier.loadVendors();
            } else {
              notifier.loadFavorites();
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGlassBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: _kTextMute, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: _kText, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '업체명·주소 검색',
                      hintStyle: TextStyle(color: _kTextMute, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) {
                      ref
                          .read(vendorNotifierProvider.notifier)
                          .search(value);
                    },
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear, color: _kTextMute, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(vendorNotifierProvider.notifier)
                            .search('');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(VendorState vendorState) {
    final selectedCategory =
        vendorState is VendorLoaded ? vendorState.selectedCategory : null;
    final isShowingFavorites =
        vendorState is VendorLoaded && vendorState.showingFavorites;

    if (isShowingFavorites) return const SizedBox(height: 12);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (code, label) = _kCategories[i];
          final selected = selectedCategory == code;
          return GestureDetector(
            onTap: () {
              if (!selected) {
                ref
                    .read(vendorNotifierProvider.notifier)
                    .selectCategory(code);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? _kPink : _kGlass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _kPink : _kGlassBorder,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.white : _kTextSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVendorList(VendorState vendorState) {
    return switch (vendorState) {
      VendorInitial() || VendorLoading() => const Center(
          child: CircularProgressIndicator(color: _kPink),
        ),
      VendorError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _kPink, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: _kTextSub, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.read(vendorNotifierProvider.notifier).loadVendors(),
                child: const Text('다시 시도',
                    style: TextStyle(color: _kPink)),
              ),
            ],
          ),
        ),
      VendorLoaded(:final vendors, :final showingFavorites) =>
        vendors.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showingFavorites
                          ? Icons.favorite_border
                          : Icons.store_outlined,
                      color: _kTextMute,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      showingFavorites
                          ? '즐겨찾기한 업체가 없습니다.'
                          : '검색 결과가 없습니다.',
                      style: const TextStyle(
                          color: _kTextSub, fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final vendor = vendors[i];
                  return _VendorCard(
                    vendor: vendor,
                    onTap: () => context.push('/vendor/${vendor.oid}'),
                    onFavoriteTap: () => ref
                        .read(vendorNotifierProvider.notifier)
                        .toggleFavorite(vendor),
                  );
                },
              ),
    };
  }
}

// ---------------------------------------------------------------------------
// _VendorCard
// ---------------------------------------------------------------------------

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _VendorCard({
    required this.vendor,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kGlassBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 아이콘
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    IconData(
                      vendor.categoryIconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: _kPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // 업체 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // 카테고리 배지
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kPink.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kPink.withOpacity(0.4)),
                            ),
                            child: Text(
                              vendor.categoryLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kPink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (vendor.address != null &&
                          vendor.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: _kTextMute),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                vendor.address!,
                                style: const TextStyle(
                                    fontSize: 11, color: _kTextSub),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (vendor.description != null &&
                          vendor.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          vendor.description!,
                          style: const TextStyle(
                              fontSize: 11, color: _kTextMute),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // 즐겨찾기 버튼
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onFavoriteTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        vendor.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        key: ValueKey(vendor.isFavorite),
                        color: vendor.isFavorite ? _kPink : _kTextMute,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
