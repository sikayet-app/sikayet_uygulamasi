import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentLocation() async {
    // GPS cihazda açık mı?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Konum servisleri kapalı. Lütfen cihazın ayarlarından konumu açın.',
      );
    }
    // izin durumunu kontrol et
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // izin istenmemiş veya reddedilmiş, tekrar iste
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Konum izni reddedildi. Bildirim oluşturmak için konum izni gerekli.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // kullanıcı bir daha sorma dedi. artık uygulama içinden izin istenmez
      throw LocationServiceException(
        'Konum izni kalıcı olarak reddedildi. Lütfen uygulama ayarlarından konum iznini manuel olarak aç',
      );
    }
    // her şey yolundaysa konumu al
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
