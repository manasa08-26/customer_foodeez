import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile_model.dart';
import '../data/repositories/profile_repository.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileModel?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async => _load();

  Future<ProfileModel?> _load() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    final addresses = await ref.read(profileRepositoryProvider).getAddresses();
    return ProfileModel(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      imageUrl: profile.imageUrl,
      addresses: addresses.isNotEmpty ? addresses : profile.addresses,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> updateProfile({String? name, String? email}) async {
    await ref.read(profileRepositoryProvider).updateProfile(
          name: name,
          email: email,
        );
    await refresh();
  }

  Future<void> addAddress({
    required String label,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,
  }) async {
    await ref.read(profileRepositoryProvider).addAddress(
          label: label,
          addressLine1: addressLine1,
          city: city,
          state: state,
          pincode: pincode,
        );
    await refresh();
  }

  Future<void> deleteAddress(String id) async {
    await ref.read(profileRepositoryProvider).deleteAddress(id);
    await refresh();
  }
}
