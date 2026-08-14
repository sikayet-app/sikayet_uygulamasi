import '../data/repositories/auth_repository.dart';
import '../data/repositories/local_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/repositories/api_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository();
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

final userByIdProvider = FutureProvider.family<User?, String>((
  ref,
  userId,
) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserById(userId);
});

final staffListProvider = FutureProvider<List<User>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getStaffList();
});

final managingListProvider = FutureProvider<List<User>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getManagingList();
});

final citizenListProvider = FutureProvider<List<User>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCitizenList();
});

final filterUserProvider = StateProvider<UserRole?>((ref) => null);

class UserListState {
  final List<User> users;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const UserListState({
    this.users = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  UserListState copyWith({
    List<User>? users,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
  }) {
    return UserListState(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class FilteredUserListNotifier extends StateNotifier<UserListState> {
  final Ref _ref;

  FilteredUserListNotifier(this._ref) : super(const UserListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = const UserListState(isLoading: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final role = _ref.read(filterUserProvider);

      final result = await repo.getUsersPage(page: 1, role: role?.name);

      state = UserListState(
        users: result.items,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = UserListState(error: e, isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final role = _ref.read(filterUserProvider);

      final result = await repo.getUsersPage(
        page: state.currentPage + 1,
        role: role?.name,
      );

      state = state.copyWith(
        users: [...state.users, ...result.items],
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final filteredUserListProvider =
    StateNotifierProvider.autoDispose<FilteredUserListNotifier, UserListState>((
      ref,
    ) {
      final notifier = FilteredUserListNotifier(ref);

      // Filtre her değiştiğinde listeyi en baştan yükle
      ref.listen<UserRole?>(
        filterUserProvider,
        (_, __) => notifier.loadFirstPage(),
      );

      return notifier;
    });
