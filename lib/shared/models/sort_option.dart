import 'package:flutter/material.dart';

enum SortOption { none, priceAsc, priceDesc, nameAsc, rating }

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.none:
        return 'Default';
      case SortOption.priceAsc:
        return 'Price: Low to High';
      case SortOption.priceDesc:
        return 'Price: High to Low';
      case SortOption.nameAsc:
        return 'Name: A – Z';
      case SortOption.rating:
        return 'Top Rated';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.none:
        return Icons.sort;
      case SortOption.priceAsc:
        return Icons.arrow_upward;
      case SortOption.priceDesc:
        return Icons.arrow_downward;
      case SortOption.nameAsc:
        return Icons.sort_by_alpha;
      case SortOption.rating:
        return Icons.star_outline;
    }
  }
}
