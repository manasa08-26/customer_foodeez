import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/discovery_controller.dart';
import '../../core/constants/app_dimensions.dart';

/// Swiggy-style home search — lives in the home header only.
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
    ref.read(discoveryControllerProvider.notifier).search(query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(discoveryControllerProvider, (prev, next) {
      if (prev?.searchQuery != next.searchQuery &&
          _controller.text != next.searchQuery) {
        _controller.text = next.searchQuery;
      }
    });

    return SizedBox(
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
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
