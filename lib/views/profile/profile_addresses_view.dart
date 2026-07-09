import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/profile_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/customer_page_scaffold.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Saved delivery addresses.
class ProfileAddressesView extends ConsumerStatefulWidget {
  const ProfileAddressesView({super.key});

  @override
  ConsumerState<ProfileAddressesView> createState() =>
      _ProfileAddressesViewState();
}

class _ProfileAddressesViewState extends ConsumerState<ProfileAddressesView> {
  final _labelCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _line1Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return CustomerPageScaffold(
      title: 'Addresses',
      fallbackLocation: RoutePaths.profile,
      child: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profile) => ResponsivePage(
          child: ListView(
            padding: EdgeInsets.all(AppDimensions.pagePadding(context)),
            children: [
              if (profile?.addresses.isEmpty ?? true)
                Text(
                  'No saved addresses',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...profile!.addresses.map(
                  (a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.label),
                    subtitle: Text(a.fullAddress, maxLines: 3),
                    trailing: a.isDefault
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(profileControllerProvider.notifier)
                                .deleteAddress(a.id),
                          ),
                  ),
                ),
              const SizedBox(height: AppDimensions.spacingXl),
              Text('Add address',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppDimensions.spacingSm),
              TextField(
                controller: _labelCtrl,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: _line1Ctrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: _stateCtrl,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              TextField(
                controller: _pinCtrl,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              AppButton(
                label: 'Save address',
                onPressed: () async {
                  await ref
                      .read(profileControllerProvider.notifier)
                      .addAddress(
                        label: _labelCtrl.text.trim(),
                        addressLine1: _line1Ctrl.text.trim(),
                        city: _cityCtrl.text.trim(),
                        state: _stateCtrl.text.trim(),
                        pincode: _pinCtrl.text.trim(),
                      );
                  _labelCtrl.clear();
                  _line1Ctrl.clear();
                  _cityCtrl.clear();
                  _stateCtrl.clear();
                  _pinCtrl.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
