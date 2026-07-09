import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/discovery_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/reference_colors.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/restaurant_card.dart';

/// Dedicated search — light screen, no veg filter.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String query) {
    ref.read(discoveryControllerProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final restaurants = state.restaurants;
    final padding = AppDimensions.pagePadding(context);

    return Scaffold(
      backgroundColor: ReferenceColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.discovery);
            }
          },
        ),
        title: const Text('Search'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              AppDimensions.spacingSm,
              padding,
              AppDimensions.spacingMd,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              onChanged: (v) {
                setState(() {});
                if (v.trim().isEmpty && state.searchQuery.isNotEmpty) {
                  _search('');
                }
              },
              decoration: InputDecoration(
                hintText: 'Search restaurants & dishes',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
          ),
          Expanded(
            child: restaurants.isEmpty
                ? EmptyStateView(
                    title: state.searchQuery.isEmpty
                        ? 'Start typing to search'
                        : 'No results',
                    subtitle: state.searchQuery.isEmpty
                        ? 'Find your favourite food'
                        : 'Try a different keyword',
                    icon: Icons.search_rounded,
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(padding),
                    itemCount: restaurants.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.spacingMd),
                    itemBuilder: (_, i) {
                      final r = restaurants[i];
                      return RestaurantCard(
                        restaurant: r,
                        index: i,
                        onTap: () => context.push(
                          RoutePaths.restaurantDetail(r.branchId),
                          extra: r.name,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
