import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/report.dart';
import '../data/models/user.dart';
import '../core/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:geocoding/geocoding.dart';
import '../core/report_ui_helpers.dart';
import '../core/app_colors.dart';
import 'dart:async'; // Timer için eklendi
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

// Konum giriş modları
enum LocationInputMode { current, manual }

class CreateReportScreen extends ConsumerStatefulWidget {
  final Report? existingReport;
  const CreateReportScreen({super.key, this.existingReport});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final TextEditingController _adressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final MapController _pickerMapController = MapController();

  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  ReportCategory _selectedCategory = ReportCategory.other;

  double? _latitude;
  double? _longitude;
  String? _district;
  String? _quarter;

  bool _isLoadingLocation = false;
  List<String> _selectedImages = [];

  // Harita durum değişkenleri
  LocationInputMode _locationMode = LocationInputMode.current;
  Timer? _debounce;
  bool _isReverseGeocoding = false;

  // formda değişiklik yapıldı mı?
  bool _hasChanges = false;

  late final MaskTextInputFormatter phoneFormatter;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);

    String initialPhone = '';

    if (widget.existingReport != null) {
      _isLoadingLocation = false;
      // YENİ: Düzenleme modunda varsayılanı manual yapıyoruz
      _locationMode = LocationInputMode.manual;

      _latitude = widget.existingReport!.latitude;
      _longitude = widget.existingReport!.longitude;
      _title = widget.existingReport!.title;
      _description = widget.existingReport!.description;
      _selectedCategory = widget.existingReport!.category;
      _selectedImages = widget.existingReport!.imagePaths.toList();
      _adressController.text = widget.existingReport!.fullAddress ?? '';
      _district = widget.existingReport!.addressDistrict;
      _quarter = widget.existingReport!.addressQuarter;

      initialPhone =
          widget.existingReport!.contactPhone ?? currentUser?.phoneNumber ?? '';
    } else {
      initialPhone = currentUser?.phoneNumber ?? '';
    }

    if (initialPhone.startsWith('0')) {
      initialPhone = initialPhone.substring(1);
    }

    phoneFormatter = MaskTextInputFormatter(
      mask: '0 (###) ### ## ##',
      filter: {"#": RegExp(r'[0-9]')},
      initialText: initialPhone, // Başlangıç metnini BURADAN veriyoruz
    );

    // Controller'a sadece formatlanmış text'i string olarak veriyoruz.
    // TextSelection vs ile uğraşmıyoruz.
    _phoneController.text = phoneFormatter.getMaskedText();
  }

  // Dispose ile memory leak önleme
  @override
  void dispose() {
    _debounce?.cancel();
    _adressController.dispose();
    _phoneController.dispose();
    _pickerMapController.dispose();
    super.dispose();
  }

  // form değişikliğini algılayıp state i güncelleyen metot
  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  // geri çıkış uyarı diyaloğu
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true; // değişiklik yoksa direkt çık

    final shoulPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Değişikleri kaydetmediniz'),
          content: const Text(
            'Yaptığınız değişiklikler kaybolacak. Çıkmak istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false), // dialogu kapat, ekranda kal
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Çık'),
            ),
          ],
        );
      },
    );
    return shoulPop ?? false;
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService().getCurrentLocation();
      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );
      final place = placemarks.first;

      _district = place.subAdministrativeArea;
      _quarter = place.subLocality;
      final adressText =
          '${place.subLocality ?? ""} Mah. ${place.thoroughfare ?? ""}, ${place.subAdministrativeArea ?? ""}';
      _adressController.text = adressText;

      _markAsChanged();
      setState(() {
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Harita kaydırıldığında tetiklenen metod
  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;

    _markAsChanged();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final center = camera.center;
      setState(() {
        _latitude = center.latitude;
        _longitude = center.longitude;
        _isReverseGeocoding = true;
      });

      try {
        final placemarks = await placemarkFromCoordinates(
          center.latitude,
          center.longitude,
        );
        final place = placemarks.first;
        _district = place.subAdministrativeArea;
        _quarter = place.subLocality;
        _adressController.text =
            '${place.subLocality ?? ""} Mah. ${place.thoroughfare ?? ""}, ${place.subAdministrativeArea ?? ""}';
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isReverseGeocoding = false);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('3 taneden fazla fotoğraf eklenemez.')),
      );
      return;
    }
    try {
      final picker = ImagePicker();
      if (source == ImageSource.camera) {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1280,
          imageQuality: 80,
        );
        if (pickedFile == null) return;
        final appDir = await getApplicationDocumentsDirectory();
        final extension = path.extension(pickedFile.path);
        final uniqueFileName = '${const Uuid().v4()}$extension';
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$uniqueFileName');
        if (mounted) {
          setState(() {
            _selectedImages.add(savedImage.path);
          });
          _markAsChanged();
        }
      }

      if (source == ImageSource.gallery) {
        final pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isEmpty) return;
        final appDir = await getApplicationDocumentsDirectory();
        for (var pickedFile in pickedFiles) {
          if (_selectedImages.length >= 3) break;
          final extension = path.extension(pickedFile.path);
          final uniqueFileName = '${const Uuid().v4()}$extension';
          final savedImage = await File(
            pickedFile.path,
          ).copy('${appDir.path}/$uniqueFileName');
          if (mounted) {
            setState(() {
              _selectedImages.add(savedImage.path);
            });
          }
        }
        _markAsChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf eklenemedi: $e')));
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // YENİ: 0.0 Atlantis Hatası Engelleme!
      if (_locationMode == LocationInputMode.current &&
          (_latitude == null || _longitude == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lütfen önce "Konumumu Kullan" butonuna tıklayarak konumunuzu alın.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        _formKey.currentState!.save();
        final currentUser = ref.read(currentUserProvider);

        double finalLatitude = _latitude ?? 0.0;
        double finalLongitude = _longitude ?? 0.0;

        final Report reportToSave;

        if (widget.existingReport != null) {
          // GÜNCELLEME MODU: Eski yetkileri (canEdit, canDelete) kaybetmemek için copyWith kullanıyoruz!
          reportToSave = widget.existingReport!.copyWith(
            title: _title,
            description: _description,
            category: _selectedCategory,
            latitude: finalLatitude,
            longitude: finalLongitude,
            imagePaths: _selectedImages,
            addressDistrict: _district,
            addressQuarter: _quarter,
            fullAddress: _adressController.text,
            contactPhone: _phoneController.text.isNotEmpty
                ? '0${phoneFormatter.getUnmaskedText()}'
                : null,
          );
        } else {
          // YENİ KAYIT MODU: Sıfırdan oluşturuyoruz.
          reportToSave = Report(
            id: const Uuid().v4(),
            title: _title,
            description: _description,
            category: _selectedCategory,
            status: ReportStatus.pending,
            latitude: finalLatitude,
            longitude: finalLongitude,
            imagePaths: _selectedImages,
            createdAt: DateTime.now(),
            userId: currentUser!.id,
            addressDistrict: _district,
            addressQuarter: _quarter,
            fullAddress: _adressController.text,
            contactPhone: _phoneController.text.isNotEmpty
                ? '0${phoneFormatter.getUnmaskedText()}'
                : null,
          );
        }

        final repository = ref.read(reportRepositoryProvider);
        if (widget.existingReport != null) {
          await repository.updateReport(reportToSave);
        } else {
          await repository.addReport(reportToSave);
        }

        ref.invalidate(reportListProvider);
        ref.invalidate(filteredReportListProvider);

        _hasChanges = false;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingReport != null
                    ? 'Şikayetiniz başarıyla güncellendi'
                    : 'Şikayetiniz başarıyla gönderildi',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(reportToSave);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingReport != null
                    ? 'Güncellenemedi: $e'
                    : 'Gönderilemedi: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (context.mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  // YARDIMCI METOT: MODÜLER KART
  Widget _buildFormSection(
    BuildContext context,
    String overline,
    Widget child,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.outline,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? colorScheme.surfaceContainerHighest
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? colorScheme.outline.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  // YENİ: TOGGLE UI TASARIMI
  Widget _buildLocationModeToggle(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeSegment(
              colorScheme,
              LocationInputMode.current,
              Icons.my_location,
              'Mevcut Konumum',
            ),
          ),
          Expanded(
            child: _buildModeSegment(
              colorScheme,
              LocationInputMode.manual,
              Icons.edit_location_alt_outlined,
              'Başka Bir Adres',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegment(
    ColorScheme colorScheme,
    LocationInputMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = _locationMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _locationMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // YENİ: MANUEL HARİTA SEÇİCİ
  Widget _buildManualAddressPicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _adressController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_outlined),
            hintText: 'Haritadan seçin veya adresi yazın',
            labelText: 'Açık Adres/Konum Tarifi',
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Adres alanı boş bırakılamaz' : null,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _pickerMapController,
                  options: MapOptions(
                    initialCenter: (_latitude != null && _longitude != null)
                        ? LatLng(_latitude!, _longitude!)
                        : const LatLng(37.0662, 37.3833), // varsayılan
                    initialZoom: 15,
                    onPositionChanged: _onMapPositionChanged,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sikayet_uygulamasi',
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 34),
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: AppColors.accent,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isReverseGeocoding)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Haritayı sürükleyerek doğru konumu işaretleyin',
          style: TextStyle(fontSize: 11, color: colorScheme.outline),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false, // otomatik geri dönmeyi engelle
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // zaten çıkıldıysa bir şey yapma

        // diyaloğu göster ve kullanıcının seçimini al
        final shoulPop = await _onWillPop();

        // eğer kullanıcı çıkmak istediyse manuel olarak çık
        if (shoulPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? colorScheme.surface
            : AppColors.surfaceWarmLight,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            widget.existingReport != null
                ? 'Bildirimi Düzenle'
                : 'Yeni Bildirim Oluştur',
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Bildirimi Gönder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              // 1. BÖLÜM: NE HAKKINDA?
              _buildFormSection(
                context,
                'NE HAKKINDA?',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: ReportCategory.values.length,
                      itemBuilder: (context, index) {
                        final category = ReportCategory.values[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.navy
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : colorScheme.outline.withValues(
                                        alpha: 0.2,
                                      ),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  getCategoryIcon(category),
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getCategoryLabel(category),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      initialValue: _title,
                      onChanged: (value) => _title = value,
                      decoration: InputDecoration(
                        labelText: 'BAŞLIK',
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: 'Örn: Sokak lambası arızalı',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Lütfen bir başlık girin'
                          : null,
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      onChanged: (value) => _description = value,
                      decoration: InputDecoration(
                        labelText: 'AÇIKLAMA',
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: 'Ne olduğunu kısaca anlatın...',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Lütfen açıklama yazınız'
                          : null,
                      onSaved: (value) => _description = value!,
                    ),
                  ],
                ),
              ),

              // 2. BÖLÜM: FOTOĞRAF
              _buildFormSection(
                context,
                'FOTOĞRAF',
                _selectedImages.isEmpty
                    ? GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          height: 150,
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera,
                                size: 40,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              const Text('Fotoğraf ekle (Maksimum 3)'),
                            ],
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...List.generate(_selectedImages.length, (index) {
                            final currentImage = _selectedImages[index];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: currentImage.startsWith('http')
                                      ? Image.network(
                                          currentImage,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                height: 100,
                                                width: 100,
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: colorScheme.outline,
                                                ),
                                              ),
                                        )
                                      : Image.file(
                                          File(currentImage),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (_selectedImages.length < 3)
                            GestureDetector(
                              onTap: _showImageSourceActionSheet,
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              // 3. BÖLÜM: YENİ BİRLEŞTİRİLMİŞ KONUM ALANI
              _buildFormSection(
                context,
                'KONUM',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationModeToggle(colorScheme),
                    const SizedBox(height: 16),

                    if (_locationMode == LocationInputMode.current) ...[
                      TextFormField(
                        controller: _adressController,
                        readOnly: true, // Elle düzenlenmesin
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          hintText: '"Konumumu Kullan" butonuna basın',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Önce konumunuzu alın'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : _fetchCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(
                            _isLoadingLocation
                                ? 'Konum alınıyor...'
                                : 'Konumumu Kullan',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.navy),
                            foregroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Salt okunur harita (Eğer koordinat bulunduysa gösterilir)
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(_latitude!, _longitude!),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.sikayet_uygulamasi',
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
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(_latitude!, _longitude!),
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.topCenter,
                                      child: Icon(
                                        Icons.location_on,
                                        color: colorScheme.primary,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ] else
                      _buildManualAddressPicker(colorScheme),
                  ],
                ),
              ),

              // 4. BÖLÜM: İLETİŞİM
              _buildFormSection(
                context,
                'İLETİŞİM',
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneFormatter],
                  decoration: InputDecoration(
                    labelText: 'İletişim Numarası',
                    hintText: '0 (5XX) XXX XX XX',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telefon numarası zorunludur.';
                    }
                    if (value.length < 17) {
                      return 'Geçerli bir telefon numarası girin.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
