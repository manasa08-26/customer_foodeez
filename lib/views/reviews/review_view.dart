import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/repositories/reviews_repository.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/responsive_page.dart';

/// Post-delivery review — mirrors web /customer/reviews/new/:orderId.
class ReviewView extends ConsumerStatefulWidget {
  const ReviewView({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<ReviewView> {
  final _textCtrl = TextEditingController();
  int _restaurantRating = 5;
  int _foodRating = 5;
  int _deliveryRating = 5;
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(reviewsRepositoryProvider).createReview(
            orderId: widget.orderId,
            restaurantRating: _restaurantRating,
            foodRating: _foodRating,
            deliveryRating: _deliveryRating,
            reviewText: _textCtrl.text.trim(),
            isAnonymous: _anonymous,
          );
      if (!mounted) return;
      context.go(RoutePaths.orderById(widget.orderId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.spacingSm),
          _RatingRow(
            label: 'Restaurant',
            value: _restaurantRating,
            onChanged: (v) => setState(() => _restaurantRating = v),
          ),
          _RatingRow(
            label: 'Food',
            value: _foodRating,
            onChanged: (v) => setState(() => _foodRating = v),
          ),
          _RatingRow(
            label: 'Delivery',
            value: _deliveryRating,
            onChanged: (v) => setState(() => _deliveryRating = v),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          TextField(
            controller: _textCtrl,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Share your experience (optional)',
            ),
          ),
          SwitchListTile(
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
            title: const Text('Post anonymously'),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          AppButton(
            label: _submitting ? 'Submitting…' : 'Submit review',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label),
          ),
          Expanded(
            child: Wrap(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => onChanged(star),
                  icon: Icon(
                    star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
