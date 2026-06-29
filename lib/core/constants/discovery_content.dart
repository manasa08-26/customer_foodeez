import 'package:flutter/material.dart';

/// Discovery static content — mirrors web `discovery/page.tsx`.
class DiscoveryCategory {
  const DiscoveryCategory({
    required this.label,
    required this.query,
    required this.imageUrl,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String label;
  final String query;
  final String imageUrl;
  final Color gradientStart;
  final Color gradientEnd;
}

class DiscoveryOffer {
  const DiscoveryOffer({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.emoji,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String tag;
  final String emoji;
  final List<Color> gradient;
}

class DiscoveryMood {
  const DiscoveryMood({
    required this.emoji,
    required this.label,
    required this.description,
    required this.query,
    required this.gradient,
  });

  final String emoji;
  final String label;
  final String description;
  final String query;
  final List<Color> gradient;
}

class DiscoveryContent {
  DiscoveryContent._();

  static const trendingChips = [
    ('Biryani', 'biryani'),
    ('Pizza', 'pizza'),
    ('Burger', 'burger'),
    ('Healthy', 'salad'),
    ('Desserts', 'dessert'),
  ];

  static const categories = <DiscoveryCategory>[
    DiscoveryCategory(
      label: 'Biryani',
      query: 'biryani',
      imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFB45309),
      gradientEnd: Color(0xFF92400E),
    ),
    DiscoveryCategory(
      label: 'Pizza',
      query: 'pizza',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFBE185D),
      gradientEnd: Color(0xFF9D174D),
    ),
    DiscoveryCategory(
      label: 'Burgers',
      query: 'burger',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFD97706),
      gradientEnd: Color(0xFFB45309),
    ),
    DiscoveryCategory(
      label: 'Wraps',
      query: 'wrap',
      imageUrl:
          'https://plus.unsplash.com/premium_photo-1678051305065-1cd54b84272e?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFF059669),
      gradientEnd: Color(0xFF047857),
    ),
    DiscoveryCategory(
      label: 'Healthy',
      query: 'salad',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFF16A34A),
      gradientEnd: Color(0xFF15803D),
    ),
    DiscoveryCategory(
      label: 'Sushi',
      query: 'sushi',
      imageUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFF0369A1),
      gradientEnd: Color(0xFF075985),
    ),
    DiscoveryCategory(
      label: 'Desserts',
      query: 'dessert',
      imageUrl:
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFF9333EA),
      gradientEnd: Color(0xFF7E22CE),
    ),
    DiscoveryCategory(
      label: 'Café',
      query: 'coffee',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFF78350F),
      gradientEnd: Color(0xFF5C2D0E),
    ),
    DiscoveryCategory(
      label: 'Noodles',
      query: 'noodles',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFDC2626),
      gradientEnd: Color(0xFFB91C1C),
    ),
    DiscoveryCategory(
      label: 'Bakery',
      query: 'bakery',
      imageUrl:
          'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFD97706),
      gradientEnd: Color(0xFF92400E),
    ),
    DiscoveryCategory(
      label: 'Chicken',
      query: 'chicken',
      imageUrl:
          'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFEA580C),
      gradientEnd: Color(0xFFC2410C),
    ),
    DiscoveryCategory(
      label: 'Curries',
      query: 'curry',
      imageUrl:
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=200&h=200&fit=crop&auto=format&q=80',
      gradientStart: Color(0xFFB45309),
      gradientEnd: Color(0xFF78350F),
    ),
  ];

  static const offers = <DiscoveryOffer>[
    DiscoveryOffer(
      title: '50% OFF',
      subtitle: 'On your first order',
      tag: 'NEW USER',
      emoji: '🎉',
      gradient: [Color(0xFF92400E), Color(0xFF7C2D12)],
    ),
    DiscoveryOffer(
      title: 'FREE Delivery',
      subtitle: 'Orders above ₹299',
      tag: 'LIMITED',
      emoji: '🚀',
      gradient: [Color(0xFF3730A3), Color(0xFF4C1D95)],
    ),
    DiscoveryOffer(
      title: '₹100 Cashback',
      subtitle: 'Apply code FEAST100',
      tag: 'HOT DEAL',
      emoji: '💰',
      gradient: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
    ),
    DiscoveryOffer(
      title: '2× Points',
      subtitle: 'On top restaurants',
      tag: 'WEEKEND',
      emoji: '⭐',
      gradient: [Color(0xFF155E75), Color(0xFF0E7490)],
    ),
  ];

  static const moods = <DiscoveryMood>[
    DiscoveryMood(
      emoji: '🔥',
      label: 'Spicy Mood',
      description: 'Hot & fiery picks',
      query: 'spicy',
      gradient: [Color(0xFF7C2D12), Color(0xFF991B1B)],
    ),
    DiscoveryMood(
      emoji: '😌',
      label: 'Comfort Food',
      description: 'Warm & cozy bites',
      query: 'comfort',
      gradient: [Color(0xFF78350F), Color(0xFF92400E)],
    ),
    DiscoveryMood(
      emoji: '🥗',
      label: 'Eating Healthy',
      description: 'Light & nutritious',
      query: 'salad',
      gradient: [Color(0xFF14532D), Color(0xFF166534)],
    ),
    DiscoveryMood(
      emoji: '⚡',
      label: 'Quick Bite',
      description: 'Ready in 15 min',
      query: 'snacks',
      gradient: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
    ),
    DiscoveryMood(
      emoji: '🌙',
      label: 'Late Night',
      description: 'Open past midnight',
      query: 'noodles',
      gradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
    ),
    DiscoveryMood(
      emoji: '🎉',
      label: 'Party Mode',
      description: 'Share with everyone',
      query: 'pizza',
      gradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    ),
    DiscoveryMood(
      emoji: '❤️',
      label: 'Date Night',
      description: 'Special & romantic',
      query: 'sushi',
      gradient: [Color(0xFF881337), Color(0xFF9F1239)],
    ),
    DiscoveryMood(
      emoji: '💪',
      label: 'Fuel Up',
      description: 'Protein-packed meals',
      query: 'chicken',
      gradient: [Color(0xFF155E75), Color(0xFF0E7490)],
    ),
  ];
}

/// Cuisine-based fallback images when API has no imageUrl.
class CuisineFallbackImages {
  CuisineFallbackImages._();

  static const _map = <String, String>{
    'biryani':
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&h=400&fit=crop&auto=format&q=75',
    'pizza':
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&h=400&fit=crop&auto=format&q=75',
    'burger':
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&h=400&fit=crop&auto=format&q=75',
    'wrap':
        'https://plus.unsplash.com/premium_photo-1678051305065-1cd54b84272e?w=600&h=400&fit=crop&auto=format&q=75',
    'salad':
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&h=400&fit=crop&auto=format&q=75',
    'sushi':
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600&h=400&fit=crop&auto=format&q=75',
    'dessert':
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&h=400&fit=crop&auto=format&q=75',
    'coffee':
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&h=400&fit=crop&auto=format&q=75',
    'noodles':
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&h=400&fit=crop&auto=format&q=75',
    'bakery':
        'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&h=400&fit=crop&auto=format&q=75',
    'chicken':
        'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=600&h=400&fit=crop&auto=format&q=75',
    'curry':
        'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&h=400&fit=crop&auto=format&q=75',
    'chinese':
        'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=600&h=400&fit=crop&auto=format&q=75',
    'indian':
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=600&h=400&fit=crop&auto=format&q=75',
    'italian':
        'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=600&h=400&fit=crop&auto=format&q=75',
    'mexican':
        'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&h=400&fit=crop&auto=format&q=75',
    'seafood':
        'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=600&h=400&fit=crop&auto=format&q=75',
    'snacks':
        'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=600&h=400&fit=crop&auto=format&q=75',
  };

  static const _pool = [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop&auto=format&q=75',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=600&h=400&fit=crop&auto=format&q=75',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&h=400&fit=crop&auto=format&q=75',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=600&h=400&fit=crop&auto=format&q=75',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&h=400&fit=crop&auto=format&q=75',
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=600&h=400&fit=crop&auto=format&q=75',
  ];

  static String forCuisine(String? cuisine, int index) {
    if (cuisine != null) {
      final key = cuisine.toLowerCase();
      for (final entry in _map.entries) {
        if (key.contains(entry.key)) return entry.value;
      }
    }
    return _pool[index % _pool.length];
  }
}
