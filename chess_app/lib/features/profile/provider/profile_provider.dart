import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../auth/provider/auth_providers.dart';

final profileProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getProfile();
});
