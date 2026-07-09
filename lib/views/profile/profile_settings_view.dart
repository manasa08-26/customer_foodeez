import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/profile_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/customer_page_scaffold.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Settings hub — edit profile, sessions, and upcoming sub-screens.
class ProfileSettingsView extends ConsumerStatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  ConsumerState<ProfileSettingsView> createState() =>
      _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends ConsumerState<ProfileSettingsView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return CustomerPageScaffold(
      title: 'Settings',
      fallbackLocation: RoutePaths.profile,
      child: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () =>
              ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (profile) {
          if (_nameCtrl.text.isEmpty) {
            _nameCtrl.text = profile?.name ?? '';
            _emailCtrl.text = profile?.email ?? '';
          }
          return ResponsivePage(
            child: ListView(
              padding: EdgeInsets.all(AppDimensions.pagePadding(context)),
              children: [
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacingSm),
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
                  label: 'Save changes',
                  onPressed: () async {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .updateProfile(
                          name: _nameCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                        );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _SettingsSection(
                  items: [
                    _SettingsMenuItem(
                      icon: Icons.devices_outlined,
                      label: 'Active sessions',
                      route: RoutePaths.sessions,
                    ),
                    _SettingsMenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notification settings',
                      route: RoutePaths.notificationSettings,
                      badge: 'Coming soon',
                    ),
                    _SettingsMenuItem(
                      icon: Icons.phone_outlined,
                      label: 'Change phone',
                      route: RoutePaths.changePhone,
                      badge: 'Coming soon',
                    ),
                    _SettingsMenuItem(
                      icon: Icons.lock_outline,
                      label: 'Privacy',
                      route: RoutePaths.privacy,
                      badge: 'Coming soon',
                    ),
                    _SettingsMenuItem(
                      icon: Icons.language_outlined,
                      label: 'Language',
                      route: RoutePaths.language,
                      badge: 'Coming soon',
                    ),
                    _SettingsMenuItem(
                      icon: Icons.delete_outline,
                      label: 'Delete account',
                      route: RoutePaths.deleteAccount,
                      badge: 'Coming soon',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsMenuItem {
  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? badge;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.items});

  final List<_SettingsMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final accent = ReferenceColors.gold(context);

    return Container(
      decoration: BoxDecoration(
        color: ReferenceColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReferenceColors.border(context)),
      ),
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: accent),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ReferenceColors.onGold(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 16,
              color: ReferenceColors.sub(context),
            ),
            onTap: () => context.push(item.route),
          );
        }).toList(),
      ),
    );
  }
}
