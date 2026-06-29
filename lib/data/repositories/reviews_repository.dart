import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_service.dart';

class ReviewsRepository {
  ReviewsRepository(this._api);

  final ApiService _api;

  Future<void> createReview({
    required String orderId,
    required int restaurantRating,
    int? foodRating,
    int? deliveryRating,
    String? reviewText,
    bool isAnonymous = false,
  }) async {
    await _api.post(
      ApiEndpoints.reviews,
      authenticated: true,
      body: {
        'orderId': orderId,
        'restaurantRating': restaurantRating,
        if (foodRating != null) 'foodRating': foodRating,
        if (deliveryRating != null) 'deliveryRating': deliveryRating,
        if (reviewText != null && reviewText.isNotEmpty)
          'reviewText': reviewText,
        'isAnonymous': isAnonymous,
      },
    );
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(apiServiceProvider));
});
