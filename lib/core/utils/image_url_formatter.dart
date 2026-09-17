const Map<String, String> _knownProductImages = {
  // Fresh Groceries & Produce (Matching Grocery UI Mockup)
  'broccoli':
      'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=600&q=80',
  'fresh-broccoli':
      'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=600&q=80',
  'cauliflower':
      'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=600&q=80',
  'red-bell-pepper':
      'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&q=80',
  'capsicum':
      'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&q=80',
  'carrot':
      'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&q=80',
  'organic-carrots':
      'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&q=80',
  'potato':
      'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600&q=80',
  'fresh-potato':
      'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600&q=80',
  'fresh-cabbage':
      'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=600&q=80',
  'cabbage':
      'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=600&q=80',
  'tomato':
      'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&q=80',
  'red-tomato':
      'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&q=80',
  'fresh-orange':
      'https://images.unsplash.com/photo-1547514701-42782101795e?w=600&q=80',
  'orange':
      'https://images.unsplash.com/photo-1547514701-42782101795e?w=600&q=80',
  'fresh-apple':
      'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600&q=80',
  'apple':
      'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600&q=80',
  'bundle-pack':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80',
  'popular-pack':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80',
  'grocery-pack':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80',
  'avocado':
      'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=600&q=80',

  // Fashion - Outerwear & Tops
  'puffer-winter-coat':
      'https://images.unsplash.com/photo-1544441893-675973e31985?w=600&q=80',
  'quilted-vest':
      'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600&q=80',
  'denim-jacket':
      'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&q=80',
  'bomber-jacket':
      'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80',
  'hooded-zip-up-sweatshirt':
      'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=600&q=80',
  'henley-button-tee':
      'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&q=80',
  'business-slim-fit-shirt':
      'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&q=80',
  'tie-dye-boho-tee':
      'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=600&q=80',
  'linen-blend-summer-shirt':
      'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80',
  'performance-dry-fit-tee':
      'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600&q=80',

  // Fashion - Bottoms
  'workout-leggings':
      'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&q=80',
  'sport-running-shorts':
      'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=600&q=80',
  'high-rise-skinny-jeans':
      'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&q=80',
  'slim-chino-pants':
      'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600&q=80',

  // Shoes & Accessories
  'woven-leather-sandals':
      'https://images.unsplash.com/photo-1603808033192-082d6919d3e1?w=600&q=80',
  'leather-oxford-shoes':
      'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=600&q=80',
  'canvas-sneakers':
      'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=600&q=80',
  'canvas-tote-bag':
      'https://images.unsplash.com/photo-1544816155-12df9643f363?w=600&q=80',
  'knit-beanie-hat':
      'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600&q=80',
  'leather-belt-classic':
      'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=600&q=80',

  // Beauty & Skincare
  'peptide-plumping-lip-balm':
      'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=600&q=80',
  'deep-sea-minerals-face-scrub':
      'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=600&q=80',
  'matte-bronzing-powder-stick':
      'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80',
  'rosemary-mint-scalp-oil':
      'https://images.unsplash.com/photo-1608248597359-052445892557?w=600&q=80',
  'collagen-peptides-facial-cream':
      'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=600&q=80',
  'purifying-scalp-scrub':
      'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=600&q=80',
  'aloe-vera-99-soothing-gel':
      'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=600&q=80',
};

const Map<String, String> _knownBannerImages = {
  'daily groceries':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
  'groceries':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
  'shoes-ready':
      'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&q=80',
  'ready to shop':
      'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&q=80',
  'cat1-removebg-preview':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
  'new arrivals':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
  'cat7-removebg-preview':
      'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
  'summer sale':
      'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
  '07-300x300':
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
  'top electronics':
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
};

const Map<String, String> _knownCategoryImages = {
  // Electronics & Tech
  'electronics':
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80',
  'electronics-gadgets':
      'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400&q=80',
  'smartphones':
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&q=80',
  'smartphones-mobile':
      'https://images.unsplash.com/photo-1598327105854-e4ee1e4f2b17?w=400&q=80',

  // Fashion & Apparel
  'fashion':
      'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&q=80',
  'fashion-apparel':
      'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400&q=80',
  't-shirts':
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&q=80',

  // Footwear & Shoes
  'footwear-shoes':
      'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80',
  'footwear':
      'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80',
  'shoes':
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',

  // Sports & Outdoors
  'sports-outdoors':
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80',
  'sports':
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80',
  'outdoors':
      'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400&q=80',

  // Accessories & Jewelry
  'accessories-jewelry':
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
  'accessories':
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
  'jewelry':
      'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=400&q=80',

  // Home & Beauty
  'home-kitchen':
      'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80',
  'health-beauty':
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
  'beauty-skincare':
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
  'beauty & skincare':
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
  'beauty':
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
  'skincare':
      'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=400&q=80',
  'cosmetics':
      'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=400&q=80',

  // Fresh Groceries
  'vegetables':
      'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&q=80',
  'fruits':
      'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400&q=80',
  'meat':
      'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400&q=80',
  'dairy':
      'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=400&q=80',
  'bakery':
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
  'bundle':
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&q=80',
  'drinks':
      'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400&q=80',
};

String _getCategoryOrKeywordFallback(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('beauty') ||
      lower.contains('skincare') ||
      lower.contains('cosmetic') ||
      lower.contains('serum') ||
      lower.contains('lip') ||
      lower.contains('cream') ||
      lower.contains('balm') ||
      lower.contains('lotion') ||
      lower.contains('scrub') ||
      lower.contains('oil') ||
      lower.contains('powder') ||
      lower.contains('blush') ||
      lower.contains('mask') ||
      lower.contains('eyeliner') ||
      lower.contains('foundation') ||
      lower.contains('perfume') ||
      lower.contains('fragrance') ||
      lower.contains('makeup')) {
    return 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80';
  }
  if (lower.contains('broccol') ||
      lower.contains('vegetable') ||
      lower.contains('cabbage') ||
      lower.contains('cauliflower') ||
      lower.contains('pepper') ||
      lower.contains('carrot') ||
      lower.contains('potato')) {
    return 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=600&q=80';
  }
  if (lower.contains('fruit') ||
      lower.contains('orange') ||
      lower.contains('apple') ||
      lower.contains('banana') ||
      lower.contains('berry') ||
      lower.contains('mango')) {
    return 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600&q=80';
  }
  if (lower.contains('pack') ||
      lower.contains('bundle') ||
      lower.contains('grocery')) {
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80';
  }
  if (lower.contains('sandals') ||
      lower.contains('shoe') ||
      lower.contains('sneaker') ||
      lower.contains('oxford') ||
      lower.contains('footwear')) {
    return 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80';
  }
  if (lower.contains('coat') ||
      lower.contains('jacket') ||
      lower.contains('vest') ||
      lower.contains('hoodie') ||
      lower.contains('sweatshirt')) {
    return 'https://images.unsplash.com/photo-1544441893-675973e31985?w=600&q=80';
  }
  if (lower.contains('shirt') ||
      lower.contains('tee') ||
      lower.contains('top')) {
    return 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&q=80';
  }
  if (lower.contains('pant') ||
      lower.contains('jean') ||
      lower.contains('chino') ||
      lower.contains('legging') ||
      lower.contains('short')) {
    return 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&q=80';
  }
  if (lower.contains('bag') ||
      lower.contains('tote') ||
      lower.contains('backpack')) {
    return 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=600&q=80';
  }
  if (lower.contains('hat') ||
      lower.contains('beanie') ||
      lower.contains('cap')) {
    return 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=600&q=80';
  }
  if (lower.contains('phone') ||
      lower.contains('electronic') ||
      lower.contains('gadget') ||
      lower.contains('audio') ||
      lower.contains('headphone')) {
    return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&q=80';
  }
  const generalFallbacks = [
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80',
    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&q=80',
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80',
    'https://images.unsplash.com/photo-1445205170230-053b83016050?w=600&q=80',
    'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80',
  ];
  final seed = text.hashCode.abs() % generalFallbacks.length;
  return generalFallbacks[seed];
}

/// Retrieves a relevant fallback image URL based on keywords, slugs, categories, or image filenames.
String getFallbackImageUrl({
  String? slug,
  String? title,
  String? category,
  String? url,
  bool isBanner = false,
  bool isCategory = false,
}) {
  final keys = <String>[
    if (slug != null && slug.isNotEmpty) slug.toLowerCase(),
    if (title != null && title.isNotEmpty) title.toLowerCase(),
    if (category != null && category.isNotEmpty) category.toLowerCase(),
    if (url != null && url.isNotEmpty) ...[
      url.toLowerCase(),
      url.split('/').last.split('.').first.toLowerCase(),
    ],
  ];

  if (isBanner) {
    for (final key in keys) {
      for (final entry in _knownBannerImages.entries) {
        if (key.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80';
  }

  if (isCategory) {
    // 1. Exact match first to avoid prefix/substring collisions
    for (final key in keys) {
      if (_knownCategoryImages.containsKey(key)) {
        return _knownCategoryImages[key]!;
      }
    }

    // 2. Exact word / substring match
    for (final key in keys) {
      for (final entry in _knownCategoryImages.entries) {
        if (key == entry.key ||
            key.contains(entry.key) ||
            entry.key.contains(key)) {
          return entry.value;
        }
      }
    }

    // 3. Keyword-based contextual fallbacks
    for (final key in keys) {
      if (key.contains('footwear') ||
          key.contains('shoe') ||
          key.contains('sneaker')) {
        return 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80';
      }
      if (key.contains('sport') ||
          key.contains('outdoor') ||
          key.contains('fitness') ||
          key.contains('active')) {
        return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80';
      }
      if (key.contains('access') ||
          key.contains('jewel') ||
          key.contains('watch')) {
        return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80';
      }
      if (key.contains('phone') || key.contains('mobile')) {
        return 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&q=80';
      }
      if (key.contains('cloth') ||
          key.contains('apparel') ||
          key.contains('fashion')) {
        return 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&q=80';
      }
      if (key.contains('elect') ||
          key.contains('gadget') ||
          key.contains('audio')) {
        return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80';
      }
      if (key.contains('beauty') ||
          key.contains('skin') ||
          key.contains('cosmetic')) {
        return 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80';
      }
    }

    // 4. Deterministic non-duplicating fallback based on slug/title hash
    const categoryFallbacks = [
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80',
      'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&q=80',
      'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80',
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80',
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&q=80',
      'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&q=80',
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
    ];
    final seed =
        (slug ?? title ?? 'category').hashCode.abs() % categoryFallbacks.length;
    return categoryFallbacks[seed];
  }

  for (final key in keys) {
    for (final entry in _knownProductImages.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
  }

  final combined =
      '${title ?? ''} ${slug ?? ''} ${category ?? ''} ${url ?? ''}';
  return _getCategoryOrKeywordFallback(combined);
}

/// Formats an image URL from the API, resolving localhost / relative paths,
/// and providing clean fallback images when deployed backend storage returns 404.
String formatImageUrl(
  String? url,
  String baseUrl, {
  String? slug,
  String? category,
  String? title,
  bool isBanner = false,
  bool isCategory = false,
  bool enableVercelFallback = true,
}) {
  final hostUrl = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  String formattedUrl = '';

  if (url != null && url.trim().isNotEmpty) {
    final trimmedUrl = url.trim();

    if (trimmedUrl.startsWith('http://localhost') ||
        trimmedUrl.startsWith('http://127.0.0.1') ||
        trimmedUrl.startsWith('http://192.168.') ||
        trimmedUrl.startsWith('http://10.0.2.2')) {
      final uri = Uri.tryParse(trimmedUrl);
      if (uri != null) {
        formattedUrl = '$hostUrl${uri.path}';
      }
    } else if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      if (trimmedUrl.startsWith('/')) {
        formattedUrl = '$hostUrl$trimmedUrl';
      } else {
        formattedUrl = '$hostUrl/storage/$trimmedUrl';
      }
    } else {
      formattedUrl = trimmedUrl;
    }
  }

  if (enableVercelFallback) {
    final isVercelStorage = formattedUrl.contains(
      'e-commers-laravel.vercel.app/storage/',
    );
    if (formattedUrl.isEmpty || isVercelStorage) {
      return getFallbackImageUrl(
        slug: slug,
        title: title,
        category: category,
        url: url,
        isBanner: isBanner,
        isCategory: isCategory,
      );
    }
  }

  return formattedUrl;
}
