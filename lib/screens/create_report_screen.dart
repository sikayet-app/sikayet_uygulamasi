import 'package:flutter/material.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/report.dart';
import '../core/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final Report? existingReport;
  const CreateReportScreen({super.key, this.existingReport});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  // tek tuşla formdaki boşlukları kontrol için
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  ReportCategory _selectedCategory = ReportCategory.other;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingReport != null) {
      _title = widget.existingReport!.title;
      _description = widget.existingReport!.description;
      _selectedCategory = widget.existingReport!.category;
      _selectedImages = widget.existingReport!.imagePaths.toList();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('3 taneden fazla fotoğraf eklenemez.')),
      );
      return;
    }
    try {
      final picker = ImagePicker();
      if (source == ImageSource.camera) {
        // kamerayı aç

        // kamerayı tetikle
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1280,
          imageQuality: 80,
        );

        // iptal kontrolü
        if (pickedFile == null) return;

        //kalıcı klasörü bul
        final appDir = await getApplicationDocumentsDirectory();

        final extension = path.extension(pickedFile.path);

        final uniqueFileName = '${const Uuid().v4()}$extension';

        // dosyayı al
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$uniqueFileName');

        if (mounted) {
          setState(() {
            _selectedImages.add(savedImage.path);
          });
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
          // dosyayı al
          final savedImage = await File(
            pickedFile.path,
          ).copy('${appDir.path}/$uniqueFileName');

          if (mounted) {
            setState(() {
              _selectedImages.add(savedImage.path);
            });
          }
        }
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
              leading: Icon(Icons.camera_alt),
              title: Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galeri'),
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
      setState(() {
        _isLoadingLocation = true;
      });

      try {
        if (widget.existingReport == null) {
          final locationService = LocationService();
          final position = await locationService.getCurrentLocation();
          _latitude = position.latitude;
          _longitude = position.longitude;
        }
        _formKey.currentState!.save();
        final currentUser = ref.read(currentUserProvider);
        final reportToSave = Report(
          id: widget.existingReport?.id ?? const Uuid().v4(),
          title: _title,
          description: _description,
          category: _selectedCategory,
          status: widget.existingReport?.status ?? ReportStatus.pending,
          latitude: widget.existingReport?.latitude ?? (_latitude ?? 0.0),
          longitude: widget.existingReport?.longitude ?? (_longitude ?? 0.0),
          imagePaths: _selectedImages,
          createdAt: widget.existingReport?.createdAt ?? DateTime.now(),
          userId: widget.existingReport?.userId ?? currentUser!.id,
        );
        final repository = ref.read(reportRepositoryProvider);
        if (widget.existingReport != null) {
          await repository.updateReport(reportToSave);
        } else {
          await repository.addReport(reportToSave);
        }
        ref.invalidate(reportListProvider);
        if (context.mounted) {
          Navigator.of(context).pop(reportToSave);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
        }
      } finally {
        if (context.mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          widget.existingReport != null
              ? 'Bildirimi Düzenle'
              : 'Yeni Bildirimler Oluştur',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Başlık',
                  prefixIcon: Icon(Icons.title),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen açıklama yazınız';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              const SizedBox(height: 16),

              _selectedImages.isEmpty
                  ? GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
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
                              color: primaryColor,
                            ),
                            SizedBox(height: 8),
                            Text('Fotoğraf ekle (Maksimum 3)'),
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
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 100,
                                                  width: 100,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
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
              const SizedBox(height: 24),
              DropdownButtonFormField<ReportCategory>(
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                value: _selectedCategory,
                items: ReportCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(getCategoryLabel(category)),
                  );
                }).toList(),
                onChanged: (selectedValue) {
                  setState(() {
                    _selectedCategory = selectedValue!;
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  child: _isLoadingLocation == true
                      ? SizedBox(
                          child: CircularProgressIndicator(color: Colors.white),
                          height: 24,
                          width: 24,
                        )
                      : Text(
                          'Bildirimi Gönder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  onPressed: _isLoadingLocation == true ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
