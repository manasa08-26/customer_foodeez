import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/discovery_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Home search row — restaurant search + veg-only toggle.
class HomeSearchBar extends ConsumerStatefulWidget {
  const HomeSearchBar({super.key});

  @override
  ConsumerState<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection = TextSelection.collapsed(offset: query.length);
    }
    ref.read(discoveryControllerProvider.notifier).search(query);
    setState(() {});
  }

  void _onQueryChanged(String value) {
    setState(() {});
    final activeQuery = ref.read(discoveryControllerProvider).searchQuery;
    if (value.trim().isEmpty && activeQuery.isNotEmpty) {
      _runSearch('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vegOnly = ref.watch(discoveryControllerProvider).vegOnly;

    ref.listen(discoveryControllerProvider, (prev, next) {
      if (prev?.searchQuery != next.searchQuery &&
          _controller.text != next.searchQuery) {
        _controller.text = next.searchQuery;
      }
    });

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppDimensions.homeSearchHeight,
            child: TextField(
              controller: _controller,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search for restaurants & dishes',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).hintColor,
                    ),
                prefixIcon: Icon(
                  Icons.search,
                  size: AppDimensions.iconMd,
                  color: Theme.of(context).hintColor,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _runSearch(''),
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _runSearch,
              onChanged: _onQueryChanged,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _VegOnlyToggle(
          value: vegOnly,
          onChanged: (v) =>
              ref.read(discoveryControllerProvider.notifier).toggleVegOnly(v),
        ),
      ],
    );
  }
}

class _VegOnlyToggle extends StatelessWidget {
  const _VegOnlyToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: SizedBox(
          height: AppDimensions.homeSearchHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: value ? AppColors.veg : Colors.transparent,
                    border: Border.all(
                      color: AppColors.veg,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'VEG',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: value ? AppColors.veg : AppColors.textSecondary,
                      ),
                ),
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.veg,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
