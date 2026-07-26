import '../data/repositories/auth_repository.dart';
import '../data/repositories/local_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

//mevcut kullanıcıyı tutucak StateProvider. şuan giriş yapmış kullancı bilgisi
final currentUserProvider = StateProvider<User?>((ref) => null);

// uygulama açılışında oturumu kontrol eden provider
final authCheckProvider = FutureProvider<User?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  if (authRepository is LocalAuthRepository) {
    await authRepository.ensureAdminExists();
  }
  final user = await authRepository.getCurrentUser();
  if (user != null) {
    ref.read(currentUserProvider.notifier).state = user;
  }
  return user;
});

final userMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final users = await ref.read(authRepositoryProvider).getAllUsers();
  // boş map oluşturma
  final Map<String, String> userMap = {};
  for (var user in users) {
    userMap[user.id] = user.name;
  }
  return userMap;
});

final userByIdProvider = FutureProvider.family<User?, String>((ref, userId) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserById(userId);
});
