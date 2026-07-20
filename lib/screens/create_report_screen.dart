import 'package:flutter/material.dart';
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
  const CreateReportScreen({super.key});

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
  List<File> _selectedImages = [];

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('3 taneden fazla fotoğraf eklenemez.')),
      );
      return;
    }
    try {
      if (source == ImageSource.camera) {
        // kamerayı aç
        final picker = ImagePicker();
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
            _selectedImages.add(savedImage);
          });
        } else if (source == ImageSource.gallery) {
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
                _selectedImages.add(savedImage);
              });
            }
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
        final locationService = LocationService();
        final position = await locationService.getCurrentLocation();
        _latitude = position.latitude;
        _longitude = position.longitude;

        _formKey.currentState!.save();
        final newReport = Report(
          id: const Uuid().v4(),
          title: _title,
          description: _description,
          category: _selectedCategory,
          latitude: _latitude ?? 0.0,
          longitude: _longitude ?? 0.0,
          imagePaths: _selectedImages.map((image) => image.path).toList(),
          createdAt: DateTime.now(),
        );
        final repository = ref.read(reportRepositoryProvider);
        await repository.addReport(newReport);
        ref.invalidate(reportListProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Bildirimler oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Başlık'),
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
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  alignLabelWithHint: true,
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        height: 150,
                        width: double.infinity,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              size: 40,
                              color: Colors.black54,
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
                        ..._selectedImages.map((image) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              image,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        }).toList(),
                        if (_selectedImages.length < 3)
                          GestureDetector(
                            onTap: _showImageSourceActionSheet,
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),

              DropdownButtonFormField<ReportCategory>(
                decoration: const InputDecoration(labelText: 'Kategori'),
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
              ElevatedButton(
                child: _isLoadingLocation == true
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Bildirimi Gönder'),
                onPressed: _isLoadingLocation == true ? null : _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
