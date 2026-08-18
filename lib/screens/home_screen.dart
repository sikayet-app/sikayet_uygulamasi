import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/report.dart';
import '../core/location_service.dart';
import '../providers/report_provider.dart';
import '../core/report_ui_helpers.dart';
import '../core/app_colors.dart';
import 'dart:io';
import 'report_detail_screen.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:sikayet_uygulamasi/widgets/create_report_fab.dart';
import 'package:flutter/foundation.dart';
import 'report_list_screen.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  LatLng? _myLocation;
  bool _isMapReady = false;
  bool _hasInitialized = false;

  static const LatLng _defaultCenter = LatLng(37.0662, 37.3833);

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(mapSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadMyLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
        if (_isMapReady) {
          _mapController.move(_myLocation!, 15);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    // Provider'ı anlık olarak dinler. Detay sayfasından haber geldiği an tetiklenir!
    ref.listen<Report?>(mapFocusProvider, (previous, next) {
      if (next != null && next.latitude != 0.0 && _isMapReady) {
        final target = LatLng(next.latitude, next.longitude);
        _mapController.move(target, 16);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showReportPreview(context, next, colorScheme, isDarkMode);
          }
        });

        // İşlem bitince sıfırla
        Future.microtask(
          () => ref.read(mapFocusProvider.notifier).state = null,
        );
      }
    });
    final state = ref.watch(filteredReportListProvider);
    final currentStatus = ref.watch(filterStatusProvider);
    final searchResults = ref.watch(mapSearchResultsProvider);

    return Scaffold(
      endDrawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: const SafeArea(child: FilterDrawerContent()),
      ),
      body: state.isLoading && state.reports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.reports.isEmpty
          ? Center(child: Text('Bildirimler yüklenemedi: ${state.error}'))
          : Stack(
              children: [
                // HARİTA
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultCenter,
                    initialZoom: 13,
                    onMapReady: () {
                      _isMapReady = true;
                      if (!_hasInitialized) {
                        _hasInitialized =
                            true; // Artık ilk açılış yapıldı olarak işaretle
                        // Harita ilk yüklendiğinde bekleyen bir odaklanma emri var mı diye bak
                        final focusTarget = ref.read(mapFocusProvider);

                        if (focusTarget != null &&
                            focusTarget.latitude != 0.0) {
                          final targetLocation = LatLng(
                            focusTarget.latitude,
                            focusTarget.longitude,
                          );

                          _mapController.move(targetLocation, 16);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _showReportPreview(
                                context,
                                focusTarget,
                                colorScheme,
                                isDarkMode,
                              );
                            }
                          });

                          // İşlem bittikten sonra haberciyi sıfırla ki harita kilitli kalmasın
                          Future.microtask(
                            () => ref.read(mapFocusProvider.notifier).state =
                                null,
                          );
                        } else {
                          _loadMyLocation();
                        }
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sikayet_uygulamasi',
                      tileBuilder: (context, tileWidget, tile) {
                        if (isDarkMode) {
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -1,
                              0,
                              0,
                              0,
                              255,
                              0,
                              -1,
                              0,
                              0,
                              255,
                              0,
                              0,
                              -1,
                              0,
                              255,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                            child: tileWidget,
                          );
                        }
                        return tileWidget;
                      },
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(50),
                        maxZoom: 15,
                        markers: state.reports.map((report) {
                          final statusColor = colorForStatus(
                            report.status,
                            isDarkMode: isDarkMode,
                          );
                          return Marker(
                            point: LatLng(report.latitude, report.longitude),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _showReportPreview(
                                  context,
                                  report,
                                  colorScheme,
                                  isDarkMode,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  getCategoryIcon(report.category),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        builder: (context, markers) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_myLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myLocation!,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4285F4,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                //  ARAMA ÇUBUĞU VE FİLTRELER
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        children: [
                          // Arama Çubuğu
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? colorScheme.surfaceContainerHighest
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    onTapOutside: (event) =>
                                        FocusScope.of(context).unfocus(),
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Bölge veya adres ara...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                Builder(
                                  builder: (innerContext) {
                                    return IconButton(
                                      icon: Icon(
                                        Icons.tune,
                                        color: colorScheme.onSurface,
                                      ),
                                      onPressed: () {
                                        Scaffold.of(
                                          innerContext,
                                        ).openEndDrawer();
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Arama Sonuçları
                          if (searchResults.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? colorScheme.surfaceContainerHighest
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: searchResults
                                    .map(
                                      (r) => ListTile(
                                        dense: true,
                                        leading: Icon(
                                          getCategoryIcon(r.category),
                                          size: 20,

                                          color: colorForStatus(
                                            r.status,
                                            isDarkMode: isDarkMode,
                                          ),
                                        ),
                                        title: Text(
                                          r.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          r.fullAddress ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        onTap: () {
                                          if (_isMapReady) {
                                            _mapController.move(
                                              LatLng(r.latitude, r.longitude),
                                              16,
                                            );
                                          }
                                          _searchController.clear();
                                          ref
                                                  .read(
                                                    mapSearchQueryProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              '';
                                          FocusScope.of(context).unfocus();
                                          _showReportPreview(
                                            context,
                                            r,
                                            colorScheme,
                                            isDarkMode,
                                          );
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),

                          // Durum Filtre Çipleri
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: const Text('Tümü'),
                                    selected: currentStatus == null,
                                    onSelected: (selected) {
                                      if (selected)
                                        ref
                                                .read(
                                                  filterStatusProvider.notifier,
                                                )
                                                .state =
                                            null;
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: isDarkMode
                                        ? colorScheme.surfaceContainerHighest
                                        : Colors.white,

                                    selectedColor: isDarkMode
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppColors.navy,
                                    labelStyle: TextStyle(
                                      color: currentStatus == null
                                          ? (isDarkMode
                                                ? colorScheme.primary
                                                : Colors.white)
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    side: BorderSide.none,
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.3,
                                    ),
                                    elevation: currentStatus == null ? 4 : 2,
                                  ),
                                ),
                                ...ReportStatus.values.map((status) {
                                  final isSelected = currentStatus == status;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      avatar: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDarkMode
                                                    ? colorScheme.primary
                                                    : Colors.white)
                                              : colorForStatus(
                                                  status,
                                                  isDarkMode: isDarkMode,
                                                ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      label: Text(getStatusLabel(status)),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected)
                                          ref
                                                  .read(
                                                    filterStatusProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              status;
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: isDarkMode
                                          ? colorScheme.surfaceContainerHighest
                                          : Colors.white,

                                      selectedColor: isDarkMode
                                          ? colorScheme.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : AppColors.navy,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? (isDarkMode
                                                  ? colorScheme.primary
                                                  : Colors.white)
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      side: BorderSide.none,
                                      elevation: isSelected ? 4 : 2,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // AKSİYON BUTONLARI
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'recenter',
                          backgroundColor: colorScheme.surface,
                          foregroundColor: colorScheme.onSurface,
                          elevation: 4,
                          onPressed: () {
                            if (_myLocation != null && _isMapReady) {
                              _mapController.move(_myLocation!, 15);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Konumunuz aranıyor...'),
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 16),

                        const CreateReportFab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Önizleme Kartı (Bottom Sheet)
  void _showReportPreview(
    BuildContext context,
    Report report,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? colorScheme.surfaceContainerHighest
                          : AppColors.surfaceWarmLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: report.imagePaths.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child:
                                report.imagePaths.first.startsWith('http') ||
                                    kIsWeb
                                ? Image.network(
                                    report.imagePaths.first,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(report.imagePaths.first),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            color: colorScheme.outline,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusBgColor(
                              report.status,
                              isDarkMode: isDarkMode,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getStatusLabel(report.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,

                              color: colorForStatus(
                                report.status,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${getCategoryLabel(report.category)} • ${report.fullAddress ?? "Adres yok"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportDetailScreen(report: report),
                      ),
                    );
                  },
                  child: const Text(
                    'Detaya Git',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
