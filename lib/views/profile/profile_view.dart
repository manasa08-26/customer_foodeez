import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/shell_tab_header.dart';

/// Profile tab — Desktop reference layout + live profile API.
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _vegMode = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authed = ref.watch(authControllerProvider).value == true;
    final gold = ReferenceColors.gold(context);

    if (!authed) {
      return Scaffold(
        backgroundColor: ReferenceColors.bg(context),
        body: SafeArea(
          child: Column(
            children: [
              const ShellTabHeader(title: 'Profile'),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: gold),
                      const SizedBox(height: 16),
                      const Text('Sign in to view your profile'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.push(RoutePaths.login),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const ShellTabHeader(title: 'Profile'),
            Expanded(
              child: profileAsync.when(
                loading: () => const LoadingView(),
                error: (_, __) => _ProfileBody(
                  name: 'Customer',
                  phone: '',
                  letter: 'U',
                  vegMode: _vegMode,
                  notifications: _notifications,
                  onVegToggle: (v) => setState(() => _vegMode = v),
                  onNotifToggle: (v) => setState(() => _notifications = v),
                  onLogout: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(RoutePaths.discovery);
                    }
                  },
                ),
                data: (profile) {
                  final name = profile?.name ?? 'Customer';
                  final phone = profile?.phone ?? profile?.email ?? '';
                  return _ProfileBody(
                    name: name,
                    phone: phone,
                    letter: name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    vegMode: _vegMode,
                    notifications: _notifications,
                    onVegToggle: (v) => setState(() => _vegMode = v),
                    onNotifToggle: (v) => setState(() => _notifications = v),
                    onLogout: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(RoutePaths.discovery);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.name,
    required this.phone,
    required this.letter,
    required this.vegMode,
    required this.notifications,
    required this.onVegToggle,
    required this.onNotifToggle,
    required this.onLogout,
  });

  final String name;
  final String phone;
  final String letter;
  final bool vegMode;
  final bool notifications;
  final ValueChanged<bool> onVegToggle;
  final ValueChanged<bool> onNotifToggle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final gold = ReferenceColors.gold(context);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ReferenceColors.card(context),
                ReferenceColors.bg(context),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push(RoutePaths.editProfile),
                    child: Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: ReferenceColors.onGold(context),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 11,
                              color: ReferenceColors.onGold(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: ReferenceColors.sub(context),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => context.push(RoutePaths.editProfile),
                          child: Row(
                            children: [
                              Text(
                                'Edit profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.edit, size: 12, color: gold),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ReferenceColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ReferenceColors.border(context)),
          ),
          child: _QuickGrid(),
        ),
        const SizedBox(height: 16),
        _MenuSection(
          items: [
            _ProfileMenuItem(
              icon: Icons.eco_outlined,
              label: 'Veg Mode',
              toggle: true,
              value: vegMode,
              onToggle: onVegToggle,
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              toggle: true,
              value: notifications,
              onToggle: onNotifToggle,
            ),
            _ProfileMenuItem(
              icon: Icons.favorite_outline,
              label: 'Favourites',
              route: RoutePaths.favourites,
            ),
            _ProfileMenuItem(
              icon: Icons.card_giftcard_outlined,
              label: 'Rewards',
              route: RoutePaths.rewards,
              badge: 'Coming soon',
            ),
            _ProfileMenuItem(
              icon: Icons.people_outline,
              label: 'Refer & Earn',
              route: RoutePaths.referral,
            ),
          ],
        ),
        _MenuSection(
          items: [
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              route: RoutePaths.profileSettings,
              badge: 'Coming soon',
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              label: 'Help & Support',
              route: RoutePaths.support,
            ),
            _ProfileMenuItem(
              icon: Icons.shield_outlined,
              label: 'Safety',
              route: RoutePaths.safety,
            ),
            _ProfileMenuItem(
              icon: Icons.info_outline,
              label: 'About FooDeeZ',
              route: RoutePaths.about,
            ),
            _ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: onLogout,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    final gold = ReferenceColors.gold(context);
    final items = [
      (Icons.location_on_outlined, 'Addresses', RoutePaths.profileAddresses),
      (Icons.restaurant_outlined, 'Dine In', RoutePaths.dinein),
      (Icons.receipt_long_outlined, 'Orders', RoutePaths.orders),
      (Icons.local_offer_outlined, 'Coupons', RoutePaths.offers),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (icon, label, route) = items[i];
        return GestureDetector(
          onTap: () => context.push(route),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: i % 2 == 0
                    ? BorderSide(
                        color: ReferenceColors.border(context),
                        width: 0.5,
                      )
                    : BorderSide.none,
                bottom: i < 2
                    ? BorderSide(
                        color: ReferenceColors.border(context),
                        width: 0.5,
                      )
                    : BorderSide.none,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: gold),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.badge,
    this.toggle = false,
    this.value = false,
    this.onToggle,
  });

  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final String? badge;
  final bool toggle;
  final bool value;
  final ValueChanged<bool>? onToggle;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final gold = ReferenceColors.gold(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                color: gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 18, color: gold),
            ),
            title: Row(
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                      color: gold,
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
            trailing: item.toggle
                ? Switch(
                    value: item.value,
                    onChanged: item.onToggle,
                  )
                : Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: ReferenceColors.sub(context),
                  ),
            onTap: item.onTap ??
                (item.route != null ? () => context.push(item.route!) : null),
          );
        }).toList(),
      ),
    );
  }
}
