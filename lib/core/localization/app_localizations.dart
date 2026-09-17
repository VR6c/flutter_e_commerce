import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Supported locales and localized strings dictionary for English (en) and Khmer (km)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('km')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    _FallbackMaterialLocalizationsDelegate(),
    _FallbackCupertinoLocalizationsDelegate(),
    _FallbackWidgetsLocalizationsDelegate(),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isKhmer => locale.languageCode == 'km';

  // ── Dictionary ─────────────────────────────────────────────────────────────
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_products': 'Products',
      'nav_wishlist': 'Wishlist',
      'nav_profile': 'Profile',
      'nav_cart': 'Cart',

      // Home Screen
      'search_placeholder': 'Search fresh groceries, organic...',
      'categories': 'Categories',
      'see_all': 'See All',
      'special_deals': 'Special Deals',
      'popular_deals': 'Popular Deals',
      'featured_products': 'Featured Products',
      'best_sellers': 'Best Sellers',
      'deliver_to': 'Deliver to',
      'select_location': 'Select Location',
      'filter': 'Filter',
      'sort_by': 'Sort By',
      'no_products_found': 'No products found',
      'try_searching_other': 'Try searching for something else',
      'suggested_for_you': 'Suggested for You',
      'suggested_for_you_sub': 'Personalized based on top ratings',
      'ai_picked': 'AI Picked',
      'fast_delivery': 'Fast Delivery',
      'organic_100': '100% Organic',
      'best_prices': 'Best Prices',
      'special_sale': 'SPECIAL SALE',
      'summer_sale': 'Summer Sale',
      'summer_sale_sub': 'Up to 50% off on selected fashion items this season.',
      'all_items': 'All Items',
      'all_products': 'All Products',

      // Product Details & Card
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'description': 'Description',
      'reviews': 'Reviews',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'quantity': 'Quantity',
      'price': 'Price',
      'color_label': 'Color',
      'size_unit_label': 'Size / Unit',
      'you_may_also_like': 'You May Also Like',
      'similar_items': 'Similar Items',
      'added_to_cart': 'Added to cart',
      'removed_from_cart': 'Removed from cart',
      'added_to_wishlist': 'Added to wishlist',
      'removed_from_wishlist': 'Removed from wishlist',

      // Cart
      'cart_title': 'Cart Page',
      'clear_cart': 'Clear Cart?',
      'clear_cart_confirm':
          'Are you sure you want to remove all items from your cart?',
      'clear': 'Clear',
      'empty_cart': 'Your cart is empty',
      'empty_cart_sub': 'Looks like you haven\'t added any items yet',
      'start_shopping': 'Start Shopping',
      'order_summary': 'Order Summary',
      'subtotal': 'Subtotal',
      'delivery_fee': 'Delivery Fee',
      'discount': 'Discount',
      'total': 'Total',
      'proceed_to_checkout': 'Proceed to Checkout',
      'coupon_code': 'Coupon Code',
      'add_promo': 'Add Promo',
      'coupon_placeholder': 'Enter coupon code',
      'applied': 'Applied',
      'coupon_applied': 'Coupon applied successfully',
      'vat_label': 'VAT (0%)',
      'weight_label': 'Weight',
      'free_label': 'FREE',

      // Checkout
      'checkout_title': 'Checkout',
      'shipping_address': 'Delivery Address',
      'payment_method': 'Payment Method',
      'aba_payway': 'ABA PAYWAY',
      'cash_on_delivery': 'Cash on Delivery (COD)',
      'credit_card': 'Credit / Debit Card',
      'place_order': 'Place Order',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'phone_number': 'Phone Number',
      'email': 'Email',
      'address': 'Address',
      'city': 'City',
      'order_notes': 'Order Notes (Optional)',
      'order_success': 'Order Placed Successfully!',
      'order_success_msg':
          'Thank you for your purchase. We are preparing your items.',
      'view_orders': 'View Orders',
      'continue_shopping': 'Continue Shopping',
      'pay_with_aba': 'Pay with ABA PAYWAY',
      'scan_qr_aba': 'Scan QR with ABA Mobile to complete your payment',

      // Auth Success & Feedback
      'account_created_title': 'Account Created Successfully!',
      'account_ready_sub':
          'Your account is ready. Discover fresh produce, organic vegetables, and daily essentials with swift delivery!',
      'perk_delivery_title': 'Express Delivery',
      'perk_delivery_sub': '30–45 mins straight to your doorstep',
      'perk_fresh_title': '100% Organic & Fresh',
      'perk_fresh_sub': 'Carefully handpicked daily from top local farms',
      'perk_deals_title': 'Member-Only Deals',
      'perk_deals_sub': 'Enjoy exclusive discounts and loyalty points',
      'signing_in': 'Signing in...',
      'welcome_back': 'Welcome back!',
      'welcome_user': 'Welcome, {name}!',
      'redirecting_in': 'Redirecting in {seconds}s...',

      // Orders
      'orders_title': 'Order History',
      'no_orders': 'No orders yet',
      'no_orders_sub': 'When you place orders, they will appear here',
      'status_pending': 'Pending',
      'status_processing': 'Processing',
      'status_shipped': 'Shipped',
      'status_delivered': 'Delivered',
      'status_cancelled': 'Cancelled',
      'order_id': 'Order ID',
      'order_date': 'Order Date',
      'items': 'Items',
      'view_receipt': 'View',
      'download_receipt': 'Download',
      'order_receipt': 'Receipt',
      'downloading_receipt': 'Downloading receipt...',
      'receipt_downloaded': 'Receipt downloaded successfully',
      'could_not_open_receipt': 'Could not open receipt.',

      // Wishlist
      'wishlist_title': 'My Wishlist',
      'empty_wishlist': 'Your wishlist is empty',
      'empty_wishlist_sub':
          'Save items you want to buy later by tapping the heart icon',

      // Profile & Settings
      'profile_title': 'My Profile',
      'edit_profile': 'Edit Profile',
      'personal_info': 'PERSONAL INFORMATION',
      'settings_pref': 'SETTINGS & PREFERENCES',
      'support_legal': 'SUPPORT & LEGAL',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'language_currency': 'Language & Currency',
      'select_language': 'Select Language',
      'language_changed': 'Language changed successfully',
      'lang_english': 'English',
      'lang_khmer': 'ភាសាខ្មែរ',
      'lang_english_sub': 'English · USD (\$)',
      'lang_khmer_sub': 'ភាសាខ្មែរ · USD (\$)',
      'help_support': 'Help & Support',
      'privacy_policy': 'Privacy Policy',
      'terms_service': 'Terms of Service',
      'log_out': 'Log Out',
      'log_out_confirm': 'Are you sure you want to log out?',
      'log_in': 'Log In',
      'create_account': 'Create Account',

      // Profile Screen Details
      'account_profile': 'Account Profile',
      'default_address': 'Default Address',
      'verified_member': 'Verified Member',
      'orders_metric': 'Orders',
      'wishlist_metric': 'Wishlist',
      'in_cart_metric': 'In Cart',
      'recent_orders': 'Recent Orders',
      'view_all': 'View All',
      'to_pay': 'To Pay',
      'processing_status': 'Processing',
      'shipped_status': 'Shipped',
      'delivered_status': 'Delivered',
      'shopping_account': 'SHOPPING & ACCOUNT',
      'my_orders': 'My Orders',
      'track_orders_sub': 'Track live orders & view history',
      'delivery_addresses': 'Delivery Addresses',
      'delivery_addresses_sub': 'Manage saved shipping addresses',
      'payment_methods': 'Payment Methods',
      'payment_methods_sub': 'Saved cards & PayWay options',
      'dark_mode_active': 'Sleek dark theme active',
      'switch_to_dark': 'Switch to dark theme',
      'push_notifications': 'Push Notifications',
      'notifications_enabled_sub': 'Order updates & offers enabled',
      'notifications_paused_sub': 'Notifications are paused',
      'notifications_enabled_msg': 'Notifications enabled',
      'notifications_disabled_msg': 'Notifications disabled',
      'help_center_support': 'Help Center & Support',
      'help_center_support_sub': '24/7 customer care & FAQs',
      'privacy_terms': 'Privacy & Terms',
      'privacy_terms_sub': 'Terms of service and privacy policy',
      'connect_with_us': 'CONNECT WITH US',
      'no_social_links': 'No social links available right now',
      'sign_out': 'Sign Out',
      'sign_out_confirm_msg':
          'Are you sure you want to sign out? You will need to log back in to access your orders and account settings.',
      'yes_sign_out': 'Yes, Sign Out',
      'welcome_to_app': 'Welcome to TVR',
      'welcome_guest_sub':
          'Sign in to manage your orders, track deliveries, and unlock member perks.',
      'live_tracking': 'Live Tracking',
      'synced_wishlist': 'Synced Wishlist',
      'exclusive_deals': 'Exclusive Deals',
      'account_details': 'Account Details',
      'change_avatar_photo': 'Change Avatar / Photo',
      'uploading_avatar': 'Uploading avatar...',
      'avatar_upload_success': 'Avatar updated successfully!',
      'avatar_upload_failed': 'Failed to upload avatar',
      'avatar_removed': 'Avatar removed',
      'email_address': 'Email address',
      'copy_email_success': 'Email address copied to clipboard',
      'payment_options': 'Payment Options',
      'aba_payway_sub': 'Fast and secure contactless checkout',
      'cod_sub': 'Pay cash when items are delivered',
      'customer_support': 'Customer Support',
      'hotline_support': 'Hotline Support',

      // Common & Actions
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'apply': 'Apply',
      'reset': 'Reset',
      'back': 'Back',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',
      'close': 'Close',
      'loading': 'Loading...',
    },
    'km': {
      // Navigation
      'nav_home': 'ទំព័រដើម',
      'nav_products': 'ផលិតផល',
      'nav_wishlist': 'បញ្ជីចង់បាន',
      'nav_profile': 'គណនី',
      'nav_cart': 'កន្ត្រក',

      // Home Screen
      'search_placeholder': 'ស្វែងរកទំនិញគុណភាពល្អៗ...',
      'categories': 'ប្រភេទ',
      'see_all': 'មើលទាំងអស់',
      'special_deals': 'ការផ្ដល់ជូនពិសេស',
      'popular_deals': 'ទំនិញពេញនិយម',
      'featured_products': 'ទំនិញពិសេសៗ',
      'best_sellers': 'លក់ដាច់បំផុត',
      'deliver_to': 'ដឹកជញ្ជូនទៅ',
      'select_location': 'ជ្រើសរើសទីតាំង',
      'filter': 'តម្រង',
      'sort_by': 'តម្រៀបតាម',
      'no_products_found': 'មិនមានផលិតផលទេ',
      'try_searching_other': 'សូមសាកល្បងស្វែងរកពាក្យផ្សេង',
      'suggested_for_you': 'ការណែនាំសម្រាប់អ្នក',
      'suggested_for_you_sub': 'ណែនាំពិសេសផ្អែកលើការវាយតម្លៃខ្ពស់',
      'ai_picked': 'ជ្រើសដោយ AI',
      'fast_delivery': 'ដឹកជញ្ជូនរហ័ស',
      'organic_100': 'គុណភាព ១០០%',
      'best_prices': 'តម្លៃល្អបំផុត',
      'special_sale': 'ប្រូម៉ូសិនពិសេស',
      'summer_sale': 'ការបញ្ចុះតម្លៃរដូវក្តៅ',
      'summer_sale_sub': 'បញ្ចុះតម្លៃរហូតដល់ 50% លើទំនិញពេញនិយម',
      'all_items': 'ទាំងអស់',
      'all_products': 'ផលិតផលទាំងអស់',

      // Product Details & Card
      'add_to_cart': 'បន្ថែមទៅកន្ត្រក',
      'buy_now': 'ទិញឥឡូវនេះ',
      'description': 'ការពិពណ៌នា',
      'reviews': 'ការវាយតម្លៃ',
      'in_stock': 'មានក្នុងស្តុក',
      'out_of_stock': 'អស់ពីស្តុក',
      'quantity': 'ចំនួន',
      'price': 'តម្លៃ',
      'color_label': 'ពណ៌',
      'size_unit_label': 'ទំហំ / ខ្នាត',
      'you_may_also_like': 'អ្នកក៏ប្រហែលជាចូលចិត្ត',
      'similar_items': 'ទំនិញស្រដៀងគ្នា',
      'added_to_cart': 'បានបន្ថែមទៅក្នុងកន្ត្រក',
      'removed_from_cart': 'បានដកចេញពីកន្ត្រក',
      'added_to_wishlist': 'បានបន្ថែមទៅបញ្ជីចង់បាន',
      'removed_from_wishlist': 'បានដកចេញពីបញ្ជីចង់បាន',

      // Cart
      'cart_title': 'កន្ត្រកទំនិញ',
      'clear_cart': 'សម្អាតកន្ត្រក?',
      'clear_cart_confirm': 'តើអ្នកពិតជាចង់លុបទំនិញទាំងអស់ចេញពីកន្ត្រកមែនទេ?',
      'clear': 'សម្អាត',
      'empty_cart': 'កន្ត្រករបស់អ្នកទទេ',
      'empty_cart_sub': 'អ្នកមិនទាន់បានបន្ថែមទំនិញនៅឡើយទេ',
      'start_shopping': 'ចាប់ផ្តើមទិញទំនិញ',
      'order_summary': 'សង្ខេបការបញ្ជាទិញ',
      'subtotal': 'សរុបតម្លៃទំនិញ',
      'delivery_fee': 'ថ្លៃដឹកជញ្ជូន',
      'discount': 'ការបញ្ចុះតម្លៃ',
      'total': 'សរុបរួម',
      'proceed_to_checkout': 'បន្តទៅកាន់ការគិតលុយ',
      'coupon_code': 'លេខកូដបញ្ចុះតម្លៃ',
      'add_promo': 'បញ្ចូលកូដបញ្ចុះតម្លៃ',
      'coupon_placeholder': 'បញ្ចូលលេខកូដបញ្ចុះតម្លៃ...',
      'applied': 'បានអនុវត្ត',
      'coupon_applied': 'បានអនុវត្តកូដបញ្ចុះតម្លៃជោគជ័យ',
      'vat_label': 'ពន្ធអាករ (VAT 0%)',
      'weight_label': 'ទម្ងន់',
      'free_label': 'ឥតគិតថ្លៃ',

      // Checkout
      'checkout_title': 'ការគិតលុយ',
      'shipping_address': 'អាសយដ្ឋានដឹកជញ្ជូន',
      'payment_method': 'វិធីសាស្ត្រទូទាត់',
      'aba_payway': 'ABA PAYWAY',
      'cash_on_delivery': 'ទូទាត់ពេលទទួលទំនិញ (COD)',
      'credit_card': 'កាតធនាគារ (Credit/Debit)',
      'place_order': 'បញ្ជាទិញឥឡូវនេះ',
      'first_name': 'នាម',
      'last_name': 'គោត្តនាម',
      'phone_number': 'លេខទូរស័ព្ទ',
      'email': 'អ៊ីមែល',
      'address': 'អាសយដ្ឋាន',
      'city': 'ទីក្រុង / ខេត្ត',
      'order_notes': 'ចំណាំបន្ថែម (ជាជម្រើស)',
      'order_success': 'ការបញ្ជាទិញទទួលបានជោគជ័យ!',
      'order_success_msg':
          'សូមអរគុណសម្រាប់ការបញ្ជាទិញ។ យើងខ្ញុំកំពុងរៀបចំទំនិញជូនអ្នក។',
      'view_orders': 'មើលការបញ្ជាទិញ',
      'continue_shopping': 'បន្តទិញទំនិញ',
      'pay_with_aba': 'ទូទាត់ជាមួយ ABA PAYWAY',
      'scan_qr_aba': 'ស្កេន QR តាមរយៈ ABA Mobile ដើម្បីបញ្ចប់ការទូទាត់',

      // Auth Success & Feedback
      'account_created_title': 'បង្កើតគណនីបានជោគជ័យ!',
      'account_ready_sub':
          'គណនីរបស់អ្នករួចរាល់ហើយ។ សូមរីករាយជាមួយទំនិញ និងសម្ភារៈប្រើប្រាស់ប្រចាំថ្ងៃជាមួយការដឹកជញ្ជូនរហ័ស!',
      'perk_delivery_title': 'ដឹកជញ្ជូនរហ័សទាន់ចិត្ត',
      'perk_delivery_sub': '៣០–៤៥ នាទីដឹកដល់មុខផ្ទះរបស់អ្នក',
      'perk_fresh_title': 'ផលិតផលថ្មីៗ ១០០%',
      'perk_fresh_sub': 'ជ្រើសរើសយ៉ាងយកចិត្តទុកដាក់ពីផលិតផលល្អៗជារៀងរាល់ថ្ងៃ',
      'perk_deals_title': 'ប្រូម៉ូសិនពិសេសសម្រាប់សមាជិក',
      'perk_deals_sub': 'ទទួលបានការបញ្ចុះតម្លៃ និងពិន្ទុសន្សំបន្ថែម',
      'signing_in': 'កំពុងចូលគណនី...',
      'welcome_back': 'សូមស្វាគមន៍មកវិញ!',
      'welcome_user': 'សូមស្វាគមន៍, {name}!',
      'redirecting_in': 'កំពុងនាំទៅកាន់ទំព័រក្នុងរយៈពេល {seconds}វិនាទី...',

      // Orders
      'orders_title': 'ប្រវត្តិការបញ្ជាទិញ',
      'no_orders': 'មិនទាន់មានការបញ្ជាទិញទេ',
      'no_orders_sub': 'នៅពេលអ្នកបញ្ជាទិញ ទំនិញនឹងបង្ហាញនៅទីនេះ',
      'status_pending': 'រង់ចាំ',
      'status_processing': 'កំពុងរៀបចំ',
      'status_shipped': 'កំពុងដឹកជញ្ជូន',
      'status_delivered': 'បានដឹកដល់',
      'status_cancelled': 'បានបោះបង់',
      'order_id': 'លេខសម្គាល់ការបញ្ជាទិញ',
      'order_date': 'កាលបរិច្ឆេទបញ្ជាទិញ',
      'items': 'ទំនិញ',
      'view_receipt': 'មើលវិក្កយបត្រ',
      'download_receipt': 'ទាញយកវិក្កយបត្រ',
      'order_receipt': 'វិក្កយបត្របញ្ជាទិញ',
      'downloading_receipt': 'កំពុងទាញយកវិក្កយបត្រ...',
      'receipt_downloaded': 'បានទាញយកវិក្កយបត្រដោយជោគជ័យ',
      'could_not_open_receipt': 'មិនអាចបើកវិក្កយបត្របានទេ',

      // Wishlist
      'wishlist_title': 'បញ្ជីចង់បាន',
      'empty_wishlist': 'បញ្ជីចង់បានរបស់អ្នកទទេ',
      'empty_wishlist_sub':
          'រក្សាទុកទំនិញដែលអ្នកចង់ទិញនៅពេលក្រោយ ដោយចុចលើរូបបេះដូង',

      // Profile & Settings
      'profile_title': 'គណនីរបស់ខ្ញុំ',
      'edit_profile': 'កែសម្រួលព័ត៌មាន',
      'personal_info': 'ព័ត៌មានផ្ទាល់ខ្លួន',
      'settings_pref': 'ការកំណត់ & ចំណង់ចំណូលចិត្ត',
      'support_legal': 'ជំនួយ & ផ្នែកច្បាប់',
      'dark_mode': 'ផ្ទៃងងឹត',
      'notifications': 'ការជូនដំណឹង',
      'language_currency': 'ភាសា & រូបិយប័ណ្ណ',
      'select_language': 'ជ្រើសរើសភាសា',
      'language_changed': 'បានផ្លាស់ប្តូរភាសាដោយជោគជ័យ',
      'lang_english': 'English',
      'lang_khmer': 'ភាសាខ្មែរ',
      'lang_english_sub': 'English · USD (\$)',
      'lang_khmer_sub': 'ភាសាខ្មែរ · USD (\$)',
      'help_support': 'ជំនួយ & ការគាំទ្រ',
      'privacy_policy': 'គោលការណ៍ឯកជនភាព',
      'terms_service': 'លក្ខខណ្ឌប្រើប្រាស់',
      'log_out': 'ចាកចេញពីគណនី',
      'log_out_confirm': 'តើអ្នកពិតជាចង់ចាកចេញពីគណនីមែនទេ?',
      'log_in': 'ចូលគណនី',
      'create_account': 'បង្កើតគណនីថ្មី',

      // Profile Screen Details
      'account_profile': 'ព័ត៌មានគណនី',
      'default_address': 'អាសយដ្ឋានលំនាំដើម',
      'verified_member': 'សមាជិកផ្ទៀងផ្ទាត់រួច',
      'orders_metric': 'ការបញ្ជាទិញ',
      'wishlist_metric': 'បញ្ជីចង់បាន',
      'in_cart_metric': 'ក្នុងកន្ត្រក',
      'recent_orders': 'ការបញ្ជាទិញថ្មីៗ',
      'view_all': 'មើលទាំងអស់',
      'to_pay': 'រង់ចាំទូទាត់',
      'processing_status': 'កំពុងរៀបចំ',
      'shipped_status': 'កំពុងដឹកជញ្ជូន',
      'delivered_status': 'បានដឹកដល់',
      'shopping_account': 'ការទិញទំនិញ & គណនី',
      'my_orders': 'ការបញ្ជាទិញរបស់ខ្ញុំ',
      'track_orders_sub': 'តាមដានការដឹក និងមើលប្រវត្តិ',
      'delivery_addresses': 'អាសយដ្ឋានដឹកជញ្ជូន',
      'delivery_addresses_sub': 'គ្រប់គ្រងអាសយដ្ឋានដឹកជញ្ជូន',
      'payment_methods': 'វិធីសាស្ត្រទូទាត់',
      'payment_methods_sub': 'កាតធនាគារ & ជម្រើស ABA PayWay',
      'dark_mode_active': 'មុខងារងងឹតកំពុងដំណើរការ',
      'switch_to_dark': 'ប្តូរទៅកាន់ផ្ទៃងងឹត',
      'push_notifications': 'ការជូនដំណឹង',
      'notifications_enabled_sub': 'បើកការជូនដំណឹងពីការកម្ម៉ង់ & ប្រូម៉ូសិន',
      'notifications_paused_sub': 'ការជូនដំណឹងត្រូវបានបិទ',
      'notifications_enabled_msg': 'បានបើកការជូនដំណឹង',
      'notifications_disabled_msg': 'បានបិទការជូនដំណឹង',
      'help_center_support': 'មជ្ឈមណ្ឌលជំនួយ & ការគាំទ្រ',
      'help_center_support_sub': 'សេវាបម្រើអតិថិជន ២៤/៧ & សំណួរញឹកញាប់',
      'privacy_terms': 'ឯកជនភាព & លក្ខខណ្ឌ',
      'privacy_terms_sub': 'លក្ខខណ្ឌប្រើប្រាស់ និងគោលការណ៍ឯកជនភាព',
      'connect_with_us': 'ភ្ជាប់ទំនាក់ទំនងជាមួយយើង',
      'no_social_links': 'មិនទាន់មានតំណបណ្តាញសង្គមនៅឡើយទេ',
      'sign_out': 'ចាកចេញពីគណនី',
      'sign_out_confirm_msg':
          'តើអ្នកពិតជាចង់ចាកចេញពីគណនីមែនទេ? អ្នកនឹងត្រូវចូលគណនីម្តងទៀតដើម្បីមើលការបញ្ជាទិញ និងការកំណត់គណនី។',
      'yes_sign_out': 'បាទ/ចាស ចាកចេញ',
      'welcome_to_app': 'សូមស្វាគមន៍មកកាន់ TVR',
      'welcome_guest_sub':
          'ចូលគណនីដើម្បីគ្រប់គ្រងការបញ្ជាទិញ តាមដានការដឹក និងទទួលបានអត្ថប្រយោជន៍ជាច្រើន។',
      'live_tracking': 'តាមដានផ្ទាល់',
      'synced_wishlist': 'បញ្ជីចង់បាន',
      'exclusive_deals': 'ការផ្ដល់ជូនពិសេស',
      'account_details': 'ព័ត៌មានលម្អិតគណនី',
      'change_avatar_photo': 'ផ្លាស់ប្តូររូបភាពគណនី',
      'uploading_avatar': 'កំពុងផ្ទុកឡើងរូបភាព...',
      'avatar_upload_success': 'បានធ្វើបច្ចុប្បន្នភាពរូបថតគណនីជោគជ័យ!',
      'avatar_upload_failed': 'បរាជ័យក្នុងការផ្ទុកឡើងរូបភាព',
      'avatar_removed': 'បានលុបរូបភាពគណនីរួចរាល់',
      'email_address': 'អាសយដ្ឋានអ៊ីមែល',
      'copy_email_success': 'បានចម្លងអាសយដ្ឋានអ៊ីមែល',
      'payment_options': 'ជម្រើសទូទាត់ប្រាក់',
      'aba_payway_sub': 'ទូទាត់រហ័ស និងមានសុវត្ថិភាពតាម QR',
      'cod_sub': 'ទូទាត់ជាសាច់ប្រាក់ពេលទទួលបានទំនិញ',
      'customer_support': 'សេវាបម្រើអតិថិជន',
      'hotline_support': 'លេខទូរស័ព្ទជំនួយ',

      // Common & Actions
      'cancel': 'បោះបង់',
      'confirm': 'យល់ព្រម',
      'save': 'រក្សាទុក',
      'delete': 'លុប',
      'apply': 'អនុវត្ត',
      'reset': 'កំណត់ឡើងវិញ',
      'back': 'ថយក្រោយ',
      'error': 'មានបញ្ហា',
      'success': 'ជោគជ័យ',
      'retry': 'ព្យាយាមម្តងទៀត',
      'close': 'បិទ',
      'loading': 'កំពុងផ្ទុក...',
    },
  };

  String text(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // ── Convenience Getters ───────────────────────────────────────────────────
  String get navHome => text('nav_home');
  String get navProducts => text('nav_products');
  String get navWishlist => text('nav_wishlist');
  String get navProfile => text('nav_profile');
  String get navCart => text('nav_cart');

  String get searchPlaceholder => text('search_placeholder');
  String get categories => text('categories');
  String get seeAll => text('see_all');
  String get specialDeals => text('special_deals');
  String get popularDeals => text('popular_deals');
  String get featuredProducts => text('featured_products');
  String get bestSellers => text('best_sellers');
  String get deliverTo => text('deliver_to');
  String get selectLocation => text('select_location');
  String get filter => text('filter');
  String get sortBy => text('sort_by');
  String get noProductsFound => text('no_products_found');
  String get trySearchingOther => text('try_searching_other');
  String get suggestedForYou => text('suggested_for_you');
  String get allProducts => text('all_products');

  String get addToCart => text('add_to_cart');
  String get buyNow => text('buy_now');
  String get description => text('description');
  String get reviews => text('reviews');
  String get inStock => text('in_stock');
  String get outOfStock => text('out_of_stock');
  String get quantity => text('quantity');
  String get price => text('price');

  String get cartTitle => text('cart_title');
  String get clearCart => text('clear_cart');
  String get clearCartConfirm => text('clear_cart_confirm');
  String get clear => text('clear');
  String get emptyCart => text('empty_cart');
  String get emptyCartSub => text('empty_cart_sub');
  String get startShopping => text('start_shopping');
  String get orderSummary => text('order_summary');
  String get subtotal => text('subtotal');
  String get deliveryFee => text('delivery_fee');
  String get discount => text('discount');
  String get total => text('total');
  String get proceedToCheckout => text('proceed_to_checkout');

  String get checkoutTitle => text('checkout_title');
  String get shippingAddress => text('shipping_address');
  String get paymentMethod => text('payment_method');
  String get abaPayWay => text('aba_payway');
  String get cashOnDelivery => text('cash_on_delivery');
  String get creditCard => text('credit_card');
  String get placeOrder => text('place_order');
  String get firstName => text('first_name');
  String get lastName => text('last_name');
  String get phoneNumber => text('phone_number');
  String get orderSuccess => text('order_success');
  String get orderSuccessMsg => text('order_success_msg');
  String get continueShopping => text('continue_shopping');

  // Auth Success Getters
  String get accountCreatedTitle => text('account_created_title');
  String get accountReadySub => text('account_ready_sub');
  String get perkDeliveryTitle => text('perk_delivery_title');
  String get perkDeliverySub => text('perk_delivery_sub');
  String get perkFreshTitle => text('perk_fresh_title');
  String get perkFreshSub => text('perk_fresh_sub');
  String get perkDealsTitle => text('perk_deals_title');
  String get perkDealsSub => text('perk_deals_sub');
  String get signingIn => text('signing_in');
  String get welcomeBack => text('welcome_back');
  String welcomeUser(String name) =>
      text('welcome_user').replaceAll('{name}', name);
  String redirectingIn(int seconds) =>
      text('redirecting_in').replaceAll('{seconds}', seconds.toString());

  String get ordersTitle => text('orders_title');
  String get orderHistory => text('orders_title');
  String get noOrders => text('no_orders');
  String get noOrdersSub => text('no_orders_sub');
  String get viewReceipt => text('view_receipt');
  String get downloadReceipt => text('download_receipt');
  String get orderReceipt => text('order_receipt');
  String get downloadingReceipt => text('downloading_receipt');
  String get receiptDownloaded => text('receipt_downloaded');
  String get couldNotOpenReceipt => text('could_not_open_receipt');
  String get wishlistTitle => text('wishlist_title');
  String get emptyWishlist => text('empty_wishlist');

  String get profileTitle => text('profile_title');
  String get editProfile => text('edit_profile');
  String get personalInfo => text('personal_info');
  String get settingsPref => text('settings_pref');
  String get supportLegal => text('support_legal');
  String get darkMode => text('dark_mode');
  String get notifications => text('notifications');
  String get languageAndCurrency => text('language_currency');
  String get selectLanguage => text('select_language');
  String get languageChanged => text('language_changed');
  String get langEnglish => text('lang_english');
  String get langKhmer => text('lang_khmer');
  String get langEnglishSub => text('lang_english_sub');
  String get langKhmerSub => text('lang_khmer_sub');
  String get logOut => text('log_out');
  String get logOutConfirm => text('log_out_confirm');
  String get logIn => text('log_in');
  String get signIn => text('log_in');
  String get createAccount => text('create_account');

  String get accountProfile => text('account_profile');
  String get defaultAddress => text('default_address');
  String get verifiedMember => text('verified_member');
  String get ordersMetric => text('orders_metric');
  String get wishlistMetric => text('wishlist_metric');
  String get inCartMetric => text('in_cart_metric');
  String get recentOrders => text('recent_orders');
  String get viewAll => text('view_all');
  String get toPay => text('to_pay');
  String get processingStatus => text('processing_status');
  String get shippedStatus => text('shipped_status');
  String get deliveredStatus => text('delivered_status');
  String get shoppingAndAccount => text('shopping_account');
  String get myOrders => text('my_orders');
  String get trackOrdersSub => text('track_orders_sub');
  String get deliveryAddresses => text('delivery_addresses');
  String get deliveryAddressesSub => text('delivery_addresses_sub');
  String get paymentMethods => text('payment_methods');
  String get paymentMethodsSub => text('payment_methods_sub');
  String get darkModeActive => text('dark_mode_active');
  String get switchToDark => text('switch_to_dark');
  String get pushNotifications => text('push_notifications');
  String get notificationsEnabledSub => text('notifications_enabled_sub');
  String get notificationsPausedSub => text('notifications_paused_sub');
  String get notificationsEnabledMsg => text('notifications_enabled_msg');
  String get notificationsDisabledMsg => text('notifications_disabled_msg');
  String get helpCenterSupport => text('help_center_support');
  String get helpCenterSupportSub => text('help_center_support_sub');
  String get privacyTerms => text('privacy_terms');
  String get privacyTermsSub => text('privacy_terms_sub');
  String get connectWithUs => text('connect_with_us');
  String get noSocialLinks => text('no_social_links');
  String get signOut => text('sign_out');
  String get signOutConfirmMsg => text('sign_out_confirm_msg');
  String get yesSignOut => text('yes_sign_out');
  String get welcomeToApp => text('welcome_to_app');
  String get guestHeroSub => text('welcome_guest_sub');
  String get liveTracking => text('live_tracking');
  String get syncedWishlist => text('synced_wishlist');
  String get exclusiveDeals => text('exclusive_deals');
  String get accountDetails => text('account_details');
  String get changeAvatarPhoto => text('change_avatar_photo');
  String get uploadingAvatar => text('uploading_avatar');
  String get avatarUploadSuccess => text('avatar_upload_success');
  String get avatarUploadFailed => text('avatar_upload_failed');
  String get avatarRemoved => text('avatar_removed');
  String get emailAddress => text('email_address');
  String get copyEmailSuccess => text('copy_email_success');
  String get paymentOptions => text('payment_options');
  String get abaPayWaySub => text('aba_payway_sub');
  String get codSub => text('cod_sub');
  String get customerSupport => text('customer_support');
  String get hotlineSupport => text('hotline_support');

  String get suggestedForYouSub => text('suggested_for_you_sub');
  String get aiPicked => text('ai_picked');
  String get fastDelivery => text('fast_delivery');
  String get organic100 => text('organic_100');
  String get bestPrices => text('best_prices');
  String get specialSale => text('special_sale');
  String get summerSale => text('summer_sale');
  String get summerSaleSub => text('summer_sale_sub');
  String get allItems => text('all_items');
  String get colorLabel => text('color_label');
  String get sizeUnitLabel => text('size_unit_label');
  String get youMayAlsoLike => text('you_may_also_like');
  String get similarItems => text('similar_items');
  String get addPromo => text('add_promo');
  String get couponPlaceholder => text('coupon_placeholder');
  String get applied => text('applied');
  String get vatLabel => text('vat_label');
  String get weightLabel => text('weight_label');
  String get freeLabel => text('free_label');

  String get cancel => text('cancel');
  String get confirm => text('confirm');
  String get save => text('save');
  String get delete => text('delete');
  String get apply => text('apply');
  String get reset => text('reset');
  String get back => text('back');
  String get error => text('error');
  String get success => text('success');
  String get retry => text('retry');
  String get close => text('close');

  // ── Smart Translation Helpers for Dynamic Catalog Content ───────────────────

  String translateCategory(String name) {
    if (!isKhmer) return name;
    final lower = name.toLowerCase().trim();
    if (lower == 'all items' || lower == 'all' || lower == 'all products') {
      return 'ទាំងអស់';
    }
    if (lower == 'electronics' || lower.contains('electronic')) {
      return 'អេឡិចត្រូនិច';
    }
    if (lower == 'fashion' || lower.contains('fashion')) {
      return 'សម្លៀកបំពាក់';
    }
    if (lower.contains('sport')) return 'កីឡា & ក្រៅផ្ទះ';
    if (lower.contains('footwear') || lower.contains('shoe')) {
      return 'ស្បែកជើង';
    }
    if (lower.contains('beauty') || lower.contains('personal care')) {
      return 'សម្រស់ & ថែទាំ';
    }
    if (lower.contains('home') || lower.contains('living')) {
      return 'គេហដ្ឋាន';
    }
    if (lower.contains('grocer') || lower.contains('food')) {
      return 'គ្រឿងទេស';
    }
    if (lower.contains('health') || lower.contains('wellness')) {
      return 'សុខភាព';
    }
    if (lower.contains('toy') || lower.contains('game')) {
      return 'ប្រដាប់ក្មេងលេង';
    }
    if (lower.contains('automotive') || lower.contains('auto')) {
      return 'យានយន្ត';
    }
    if (lower.contains('book')) return 'សៀវភៅ';
    if (lower.contains('bag') || lower.contains('luggage')) {
      return 'កាបូប & វ៉ាលី';
    }
    if (lower.contains('watch') || lower.contains('jewelry')) {
      return 'នាឡិកា & គ្រឿងអលង្ការ';
    }
    return name;
  }

  String translateColor(String color) {
    if (!isKhmer) return color;
    final lower = color.toLowerCase().trim();
    if (lower == 'white') return 'ពណ៌ស';
    if (lower == 'black') return 'ពណ៌ខ្មៅ';
    if (lower == 'gold') return 'ពណ៌មាស';
    if (lower == 'silver') return 'ពណ៌ប្រាក់';
    if (lower == 'red') return 'ពណ៌ក្រហម';
    if (lower == 'blue') return 'ពណ៌ខៀវ';
    if (lower == 'green') return 'ពណ៌បៃតង';
    if (lower == 'yellow') return 'ពណ៌លឿង';
    if (lower == 'grey' || lower == 'gray') return 'ពណ៌ប្រផេះ';
    if (lower == 'pink') return 'ពណ៌ផ្កាឈូក';
    if (lower == 'purple') return 'ពណ៌ស្វាយ';
    if (lower == 'orange') return 'ពណ៌ទឹកក្រូច';
    if (lower == 'brown') return 'ពណ៌ត្នោត';
    return color;
  }

  String translateSize(String size) {
    if (!isKhmer) return size;
    final lower = size.toLowerCase().trim();
    if (lower == 's' || lower == 'small') return 'តូច (S)';
    if (lower == 'm' || lower == 'medium') return 'មធ្យម (M)';
    if (lower == 'l' || lower == 'large') return 'ធំ (L)';
    if (lower == 'xl' || lower == 'extra large') return 'ធំពិសេស (XL)';
    if (lower == 'xxl' || lower == '2xl') return 'ធំពិសេស (XXL)';
    return size;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'km'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class _FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

class _FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackWidgetsLocalizationsDelegate old) => false;
}

extension AppLocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).text(key);
}
