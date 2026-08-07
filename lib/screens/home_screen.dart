import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/report.dart';
import '../core/location_service.dart';
import '../providers/report_provider.dart';
import '../core/report_ui_helpers.dart';
import 'dart:io';
import 'report_detail_screen.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'; // EKSİK NOKTALI VİRGÜL EKLENDİ

// consumer: db ye yeni şikayet gelirse harita bunu anında gösterecek
// stateful: hafızası olan,zamanla değişebilen. konumum değiştikçe mavi nokta hareket edecek.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng? _myLocation;
  bool _isMapReady = false; // haritanın ekrana çizilip çizilmediği anlaşılacak
  static const LatLng _defaultCenter = LatLng(
    37.0662,
    37.3833,
  ); // kullanıcının gps i kapalıysa diye varsayılan merkez noktası.

  // bir kereliğine çalışır
  @override
  void initState() {
    super.initState();
    _loadMyLocation();
  }

  Future<void> _loadMyLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
        if (_isMapReady) {
          _mapController.move(_myLocation!, 15); // 15: mahalle,sokak seviyesi
        }
      }
    }
    // gps izni verilmezse veya telefon bozuksa hatayı gösterme, default konumu göster.
    catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(filteredReportListProvider);
    return Scaffold(
      body: reportAsync.when(
        data: (reports) => Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 13,
                //harita tamamen çizilip hazır olduğunda tetiklenir
                onMapReady: () {
                  _isMapReady = true;
                  if (_myLocation != null) {
                    _mapController.move(_myLocation!, 15);
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sikayet_uygulamasi',
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: reports.map((report) {
                      return Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showReportPreview(context, report),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorForStatus(report.status),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.report_problem,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: const [
                            // EKSİK KÖŞELİ PARANTEZ EKLENDİ
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ), // FLUTTERMAP BİTİŞİ EKLENDİ VE VİRGÜL KONULDU
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'recenter',
                onPressed: () {
                  if (_myLocation != null && _isMapReady) {
                    _mapController.move(_myLocation!, 15);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Konumunuz aranıyor...')),
                    );
                  }
                },
                child: const Icon(Icons.center_focus_strong),
              ),
            ),
          ],
        ),
        error: (error, StackTrace) =>
            Center(child: Text('Bildirimler yüklenemedi: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showReportPreview(BuildContext context, Report report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                report.imagePaths.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: report.imagePaths.first.startsWith('http')
                            ? Image.network(
                                report.imagePaths.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(report.imagePaths.first),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        width: 80,
                        height: 80,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, // uzunsa tek satırda kalsın
                        overflow:
                            TextOverflow.ellipsis, // sığmazsa sonuna ... koysun
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            getFormattedDate(report.createdAt),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              report.fullAddress ?? 'Adres belirtilmemiş',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        style: TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    getCategoryLabel(report.category),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorForStatus(report.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getStatusLabel(report.status),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('Detaya Git'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(report: report),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
