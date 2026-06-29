import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/sessions_controller.dart';
import '../../core/constants/app_dimensions.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/responsive_page.dart';

/// Active sessions — mirrors web /customer/sessions.
class SessionsView extends ConsumerWidget {
  const SessionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsControllerProvider);

    return sessionsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorStateView.fromError(
        e,
        onRetry: () => ref.read(sessionsControllerProvider.notifier).refresh(),
      ),
      data: (sessions) => ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage devices where you are signed in',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            if (sessions.isEmpty)
              const Text('No active sessions found')
            else
              ...sessions.map(
                (s) => Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                  child: ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(
                      s.userAgent ?? 'Unknown device',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: s.lastUsedAt != null
                        ? Text('Last used: ${s.lastUsedAt!.toLocal()}')
                        : null,
                    trailing: s.isCurrent
                        ? const Chip(label: Text('Current'))
                        : TextButton(
                            onPressed: () => ref
                                .read(sessionsControllerProvider.notifier)
                                .revoke(s.deviceId),
                            child: const Text('Revoke'),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: AppDimensions.spacingXl),
            AppButton(
              label: 'Sign out all devices',
              variant: AppButtonVariant.outline,
              onPressed: () async {
                await ref.read(sessionsControllerProvider.notifier).logoutAll();
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(RoutePaths.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
