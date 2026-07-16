import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/report.dart';
import '../core/location_service.dart';
import '../providers/report_provider.dart';

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

  Color _colorForStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.red;
      case ReportStatus.inProgress:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportListProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Şikayet Haritası')),
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
                MarkerLayer(
                  markers: [
                    ...reports.map((report) {
                      return Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showReportPreview(context, report),
                          child: Icon(
                            Icons.location_pin,
                            color: _colorForStatus(report.status),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                    if (_myLocation != null)
                      Marker(
                        point: _myLocation!,
                        width: 24,
                        height: 24,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
            Text(report.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${getCategoryLabel(report.category)} & ${getStatusLabel(report.status)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(report.description),
          ],
        ),
      ),
    );
  }
}
