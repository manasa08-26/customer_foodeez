import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/profile_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/error_messages.dart';
import '../../data/models/profile_model.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Profile with tabs — mirrors web /customer/profile.
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _labelCtrl.dispose();
    _line1Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _fillProfile(ProfileModel? profile) {
    if (profile == null) return;
    if (_nameCtrl.text.isEmpty) _nameCtrl.text = profile.name ?? '';
    if (_emailCtrl.text.isEmpty) _emailCtrl.text = profile.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return profileAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) {
        final msg = ErrorMessages.userFriendly(e);
        final needsLogin = msg.toLowerCase().contains('auth');
        return ErrorStateView(
          message: needsLogin ? 'Please sign in to view your profile' : msg,
          onRetry: needsLogin
              ? () => context.push(RoutePaths.login)
              : () => ref.read(profileControllerProvider.notifier).refresh(),
        );
      },
      data: (profile) {
        _fillProfile(profile);
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.pagePadding(context),
                AppDimensions.spacingMd,
                AppDimensions.pagePadding(context),
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (profile?.name ?? 'U').substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(
                        profile?.name ?? 'Customer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [profile?.email, profile?.phone]
                            .whereType<String>()
                            .join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  _QuickActions(),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Addresses'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  ResponsivePage(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        AppButton(
                          label: 'Save profile',
                          onPressed: () async {
                            await ref
                                .read(profileControllerProvider.notifier)
                                .updateProfile(
                                  name: _nameCtrl.text.trim(),
                                  email: _emailCtrl.text.trim(),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  ResponsivePage(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (profile?.addresses.isEmpty ?? true)
                          const Text('No saved addresses')
                        else
                          ...profile!.addresses.map(
                            (a) => Card(
                              margin: const EdgeInsets.only(
                                bottom: AppDimensions.spacingSm,
                              ),
                              child: ListTile(
                                title: Text(a.label),
                                subtitle: Text(
                                  a.fullAddress,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: a.isDefault
                                    ? const Chip(label: Text('Default'))
                                    : IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => ref
                                            .read(profileControllerProvider
                                                .notifier)
                                            .deleteAddress(a.id),
                                      ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        Text('Add address',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppDimensions.spacingSm),
                        TextField(
                          controller: _labelCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Label (Home, Work)',
                          ),
                        ),
                        TextField(
                          controller: _line1Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Address line',
                          ),
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
                        const SizedBox(height: AppDimensions.spacingSm),
                        AppButton(
                          label: 'Add address',
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Orders', Icons.receipt_long_outlined, RoutePaths.orders),
      ('Wallet', Icons.account_balance_wallet_outlined, RoutePaths.payments),
      ('Support', Icons.support_agent_outlined, RoutePaths.support),
      ('Sessions', Icons.devices_outlined, RoutePaths.sessions),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.spacingSm,
          crossAxisSpacing: AppDimensions.spacingSm,
          childAspectRatio: 1.6,
          children: items.map((item) {
            final (label, icon, route) = item;
            return Card(
              child: InkWell(
                onTap: () => context.go(route),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22),
                    const SizedBox(height: 4),
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
