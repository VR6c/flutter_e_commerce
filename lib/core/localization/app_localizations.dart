import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supported locales and localized strings loader for English (en) and Khmer (km)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale) {
    _ensureLoaded(locale.languageCode);
  }

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

  static final Map<String, Map<String, String>> _localizedValues = {};

  static Future<AppLocalizations> load(Locale locale) async {
    final langCode = locale.languageCode;
    if (_localizedValues[langCode] == null || _localizedValues[langCode]!.isEmpty) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/translations/$langCode.json',
        );
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _localizedValues[langCode] = jsonMap.map(
          (k, v) => MapEntry(k, v.toString()),
        );
      } catch (_) {
        _loadFromFileSystem(langCode);
      }
    }
    if (langCode != 'en' && (_localizedValues['en'] == null || _localizedValues['en']!.isEmpty)) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/translations/en.json',
        );
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _localizedValues['en'] = jsonMap.map(
          (k, v) => MapEntry(k, v.toString()),
        );
      } catch (_) {
        _loadFromFileSystem('en');
      }
    }
    return AppLocalizations(locale);
  }

  static void _ensureLoaded(String langCode) {
    if (_localizedValues[langCode] == null || _localizedValues[langCode]!.isEmpty) {
      _loadFromFileSystem(langCode);
    }
    if (_localizedValues['en'] == null || _localizedValues['en']!.isEmpty) {
      _loadFromFileSystem('en');
    }
  }

  static void _loadFromFileSystem(String langCode) {
    try {
      final file = File('assets/translations/$langCode.json');
      if (file.existsSync()) {
        final Map<String, dynamic> jsonMap = json.decode(file.readAsStringSync());
        _localizedValues[langCode] = jsonMap.map(
          (k, v) => MapEntry(k, v.toString()),
        );
      }
    } catch (_) {}
  }

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
  String get freeDelivery => text('free_delivery');
  String get free => text('free');
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
  String get loading => text('loading');

  String get termsService => text('terms_service');
  String get privacyPolicy => text('privacy_policy');
  String get helpSupport => text('help_support');
  String get addedToWishlist => text('added_to_wishlist');
  String get removedFromWishlist => text('removed_from_wishlist');
  String get addedToCart => text('added_to_cart');
  String get removedFromCart => text('removed_from_cart');
  String get emptyWishlistSub => text('empty_wishlist_sub');
  String get couponCode => text('coupon_code');
  String get couponApplied => text('coupon_applied');
  String get payWithAba => text('pay_with_aba');
  String get scanQrAba => text('scan_qr_aba');
  String get viewOrders => text('view_orders');
  String get orderId => text('order_id');
  String get orderDate => text('order_date');
  String get items => text('items');
  String get orderNotes => text('order_notes');
  String get address => text('address');
  String get city => text('city');
  String get email => text('email');
  String get statusPending => text('status_pending');
  String get statusProcessing => text('status_processing');
  String get statusShipped => text('status_shipped');
  String get statusDelivered => text('status_delivered');
  String get statusCancelled => text('status_cancelled');


  // ── Centralized App Copy Getters ──────────────────────────────────────────

  String get abaPayway => text('aba_payway');
  String get languageCurrency => text('language_currency');
  String get shoppingAccount => text('shopping_account');
  String get welcomeGuestSub => text('welcome_guest_sub');
  String get abaPaywaySub => text('aba_payway_sub');
  String get waitingAbaPayment => text('waiting_aba_payment');
  String get waitingAbaPaymentSub => text('waiting_aba_payment_sub');
  String get checkStatusNow => text('check_status_now');
  String get checkingStatus => text('checking_status');
  String get paymentTimeout => text('payment_timeout');
  String get paymentTimeoutSub => text('payment_timeout_sub');
  String get viewInMyOrders => text('view_in_my_orders');
  String get payWithKhqr => text('pay_with_khqr');
  String get cancelPayment => text('cancel_payment');
  String get openAbaMobile => text('open_aba_mobile');
  String get restartStatusCheck => text('restart_status_check');
  String get tryCheckingAgain => text('try_checking_again');
  String get qrValidityTimedOut => text('qr_validity_timed_out');
  String get abaNotInstalled => text('aba_not_installed');
  String get scanKhqrInstructions => text('scan_khqr_instructions');
  String get clearAllFilters => text('clear_all_filters');
  String get unableToLoadProducts => text('unable_to_load_products');
  String get noProductsAvailable => text('no_products_available');
  String get checkBackLaterStock => text('check_back_later_stock');
  String get tryAdjustingSearch => text('try_adjusting_search');
  String get matchingItems => text('matching_items');
  String get inCategories => text('in_categories');
  String get trendingSearches => text('trending_searches');
  String get instantSuggestions => text('instant_suggestions');
  String get noInstantSuggestions => text('no_instant_suggestions');
  String get couldNotLoadSuggestions => text('could_not_load_suggestions');
  String get clearFilters => text('clear_filters');
  String get tryClearingFilter => text('try_clearing_filter');
  String get checkBackLaterItems => text('check_back_later_items');
  String get filteredResults => text('filtered_results');
  String get locationLabelHome => text('location_label_home');
  String get locationLabelWork => text('location_label_work');
  String get locationLabelOffice => text('location_label_office');
  String get pinDeliveryLocation => text('pin_delivery_location');
  String get selectedLocation => text('selected_location');
  String get locatingAddress => text('locating_address');
  String get confirmDeliveryLocation => text('confirm_delivery_location');
  String get searchResults => text('search_results');
  String get categoryItems => text('category_items');
  String get ourBestItems => text('our_best_items');
  String get clearAll => text('clear_all');
  String get sortFilter => text('sort_filter');
  String get resetAll => text('reset_all');
  String get priceRange => text('price_range');
  String get allPrices => text('all_prices');
  String get customerRating => text('customer_rating');
  String get noProductsMatch => text('no_products_match');
  String get all => text('all');
  String get pleaseEnterAStreetAddress => text('please_enter_a_street_address');
  String get chooseDeliveryLocation => text('choose_delivery_location');
  String get groceriesWillBeDeliveredTo => text('groceries_will_be_delivered_to');
  String get searchAreaStreetOrLandmark => text('search_area_street_or_landmark');
  String get setLocationOnMap => text('set_location_on_map');
  String get interactive => text('interactive');
  String get dragPinToYourExact => text('drag_pin_to_your_exact');
  String get savedAddresses => text('saved_addresses');
  String get defaultBadge => text('default');
  String get addNewAddress => text('add_new_address');
  String get addDeliveryAddress => text('add_delivery_address');
  String get addressLabel => text('address_label');
  String get customLabelEgGymFriend => text('custom_label_eg_gym_friend');
  String get streetHouseBuilding => text('street_house_building');
  String get egStreet2004SenSok => text('eg_street_2004_sen_sok');
  String get cityDistrict => text('city_district');
  String get phnomPenh => text('phnom_penh');
  String get saveDeliverHere => text('save_deliver_here');
  String get welcomeToTvr => text('welcome_to_tvr');
  String get greatQualityAndQuickShipping => text('great_quality_and_quick_shipping');
  String get v100FastSecureDelivery => text('v100_fast_secure_delivery');
  String get tryAgain => text('try_again');
  String get continueAsGuest => text('continue_as_guest');
  String get totalPrice => text('total_price');
  String get highQualityProductAreCarefully => text('high_quality_product_are_carefully');
  String get viewCart => text('view_cart');
  String get joinUsToGetFresh => text('join_us_to_get_fresh');
  String get fullName => text('full_name');
  String get johnDoe => text('john_doe');
  String get fullNameIsRequired => text('full_name_is_required');
  String get emailIsRequired => text('email_is_required');
  String get pleaseEnterAValidEmail => text('please_enter_a_valid_email');
  String get password => text('password');
  String get atLeast6Characters => text('at_least_6_characters');
  String get passwordIsRequired => text('password_is_required');
  String get passwordMustBeAtLeast => text('password_must_be_at_least');
  String get confirmPassword => text('confirm_password');
  String get reenterYourPassword => text('reenter_your_password');
  String get pleaseConfirmYourPassword => text('please_confirm_your_password');
  String get passwordsDoNotMatch => text('passwords_do_not_match');
  String get alreadyHaveAnAccount => text('already_have_an_account');
  String get loginFailedPleaseVerifyYour => text('login_failed_please_verify_your');
  String get invalidEmailOrPasswordPlease => text('invalid_email_or_password_please');
  String get resetYourPassword => text('reset_your_password');
  String get pleaseEnterYourPhoneNumber => text('please_enter_your_phone_number');
  String get enterPhoneNumberOrEmail => text('enter_phone_number_or_email');
  String get sendVerificationCode => text('send_verification_code');
  String get welcomeBackTonourGroceryShop => text('welcome_back_tonour_grocery_shop');
  String get signInToExploreOrganic => text('sign_in_to_explore_organic');
  String get emailOrMobile => text('email_or_mobile');
  String get fieldIsRequired => text('field_is_required');
  String get pleaseEnterAValidEmail1 => text('please_enter_a_valid_email_1');
  String get enterYourPassword => text('enter_your_password');
  String get forgotPassword => text('forgot_password');
  String get login => text('login');
  String get dontHaveAnAccount => text('dont_have_an_account');
  String get signUp => text('sign_up');
  String get secureCheckout => text('secure_checkout');
  String get chooseHowYou => text('choose_how_you');
  String get accessYourAccountSavedAddresses => text('access_your_account_saved_addresses');
  String get returningCustomer => text('returning_customer');
  String get saveYourDetailsTrackOrders => text('save_your_details_track_orders');
  String get newCustomer => text('new_customer');
  String get checkoutAsGuest => text('checkout_as_guest');
  String get noAccountNeededJustEnter => text('no_account_needed_just_enter');
  String get fastestOption => text('fastest_option');
  String get whyCreateAnAccount => text('why_create_an_account');
  String get trackOrders => text('track_orders');
  String get backToHome => text('back_to_home');
  String get successfullySignedIn => text('successfully_signed_in');
  String get brands => text('brands');
  String get noBrandsFound => text('no_brands_found');
  String get noBrandsAreRegisteredAt => text('no_brands_are_registered_at');
  String get customizeAvatar => text('customize_avatar');
  String get livePreviewAutosaved => text('live_preview_autosaved');
  String get applyUseThisAvatar => text('apply_use_this_avatar');
  String get emailCopiedToClipboard => text('email_copied_to_clipboard');
  String get done => text('done');
  String get customerId => text('customer_id');
  String get status => text('status');
  String get editInfo => text('edit_info');
  String get profileUpdatedSuccessfully => text('profile_updated_successfully');
  String get tapToChangePhotoOr => text('tap_to_change_photo_or');
  String get enterYourFullName => text('enter_your_full_name');
  String get enterYourEmailAddress => text('enter_your_email_address');
  String get pleaseEnterAValidEmail2 => text('please_enter_a_valid_email_2');
  String get changePassword => text('change_password');
  String get currentPassword => text('current_password');
  String get currentPasswordIsRequiredTo => text('current_password_is_required_to');
  String get newPasswordMin6Characters => text('new_password_min_6_characters');
  String get newPasswordMustBeAt => text('new_password_must_be_at');
  String get confirmNewPassword => text('confirm_new_password');
  String get saveChanges => text('save_changes');
  String get defaultInitials => text('default_initials');
  String get uploadedPhoto => text('uploaded_photo');
  String get customAvatar => text('custom_avatar');
  String get profilePictureAvatar => text('profile_picture_avatar');
  String get designHairFaceClothesAnd => text('design_hair_face_clothes_and');
  String get takePhoto => text('take_photo');
  String get useCameraToSnapA => text('use_camera_to_snap_a');
  String get chooseFromGallery => text('choose_from_gallery');
  String get selectAnImageFromYour => text('select_an_image_from_your');
  String get resetToDefaultAvatar => text('reset_to_default_avatar');
  String get removePhotoOrAvatarAnd => text('remove_photo_or_avatar_and');
  String get homeDefaultDelivery => text('home_default_delivery');
  String get phnomPenhCityCambodianstreet271 => text('phnom_penh_city_cambodianstreet_271');
  String get guestCheckout => text('guest_checkout');
  String get change => text('change');
  String get selectDeliveryAddress => text('select_delivery_address');
  String get detailedStreetAddress => text('detailed_street_address');
  String get addressIsRequired => text('address_is_required');
  String get contactInformation => text('contact_information');
  String get required => text('required');
  String get phoneIsRequired => text('phone_is_required');
  String get validEmailRequired => text('valid_email_required');
  String get creditCard1 => text('credit_card_1');
  String get cashOnDel => text('cash_on_del');
  String get cardNumber => text('card_number');
  String get mmyy => text('mmyy');
  String get saveCardForFuturePayments => text('save_card_for_future_payments');
  String get orderReference => text('order_reference');
  String get paymentType => text('payment_type');
  String get estimatedDelivery => text('estimated_delivery');
  String get today3045Mins => text('today_3045_mins');
  String get officialInvoiceForThisOrder => text('official_invoice_for_this_order');
  String get orderSavedSignInAnytime => text('order_saved_sign_in_anytime');
  String get trackOrder => text('track_order');
  String get loadingReceipt => text('loading_receipt');
  String get failedToLoadReceipt => text('failed_to_load_receipt');
  String get pleaseTryAgainOrOpen => text('please_try_again_or_open');
  String get downloading => text('downloading');
  String get signInToViewOrders => text('sign_in_to_view_orders');
  String get signInToTrackLive => text('sign_in_to_track_live');
  String get couldNotLoadOrders => text('could_not_load_orders');
  String get noItemDetailsAvailable => text('no_item_details_available');
  String get completed => text('completed');
  String get previewOnScreenOrDownload => text('preview_on_screen_or_download');
  String get downloading1 => text('downloading_1');
  String get receiptDownloaded1 => text('receipt_downloaded_1');
  String get savedInAppleFilesApp => text('saved_in_apple_files_app');
  String get done1 => text('done_1');
  String get sortProducts => text('sort_products');
  String get tryADifferentSearchTerm => text('try_a_different_search_term');
  String get noProductsAreAvailableIn => text('no_products_are_available_in');
  String get clearWishlist => text('clear_wishlist');
  String get doYouWantToRemove => text('do_you_want_to_remove');
  String get saveYourFavoriteItemsAnd => text('save_your_favorite_items_and');
  String get exploreProducts => text('explore_products');
  String get signInToViewWishlist => text('sign_in_to_view_wishlist');
  String get signInToSyncYour => text('sign_in_to_sync_your');
  String get promotion => text('promotion');
  String get seasonal => text('seasonal');
  String get featured => text('featured');
  String get announcement => text('announcement');
  String get freshDeals => text('fresh_deals');
  String get splashPleaseWait => text('splash_please_wait');
  String get splashStarting => text('splash_starting');
  String get splashReady => text('splash_ready');
  String get splashInitError => text('splash_init_error');

  // ── Parameterized Translation Helpers ─────────────────────────────────────

  String autoCheckingStatus(String time) =>
      text('auto_checking_status').replaceAll('{time}', time);

  String checkingPaymentStatus(String time) =>
      text('checking_payment_status').replaceAll('{time}', time);

  String noProductsInCategory(String category) =>
      text('no_products_in_category').replaceAll('{category}', category);

  String deliveryAddressSet(String label) =>
      text('delivery_address_set').replaceAll('{label}', label);

  String noAddressesMatching(String query) =>
      text('no_addresses_matching').replaceAll('{query}', query);

  String pinnedAddressSaved(String address) =>
      text('pinned_address_saved').replaceAll('{address}', address);

  String greetingUser(String name) =>
      text('greeting_user').replaceAll('{name}', name);

  String itemCountLabel(int count) =>
      text('item_count_label').replaceAll('{count}', count.toString());

  String orderNumber(dynamic id) =>
      text('order_number').replaceAll('{id}', id.toString());

  String itemsCount(int count) =>
      text('items_count').replaceAll('{count}', count.toString());

  String qtyCount(dynamic quantity) =>
      text('qty_count').replaceAll('{quantity}', quantity.toString());

  String officialReceiptNumber(dynamic id) =>
      text('official_receipt_number').replaceAll('{id}', id.toString());

  String receiptDownloadedFile(String file) =>
      text('receipt_downloaded_file').replaceAll('{file}', file);

  String searchInCategory(String category) =>
      text('search_in_category').replaceAll('{category}', category);

  String noResultsForQuery(String query) =>
      text('no_results_for_query').replaceAll('{query}', query);

  String addedProductToCart(String name) =>
      text('added_product_to_cart').replaceAll('{name}', name);

  String addedQuantityToCart(int quantity, String name) =>
      text('added_quantity_to_cart')
          .replaceAll('{quantity}', quantity.toString())
          .replaceAll('{name}', name);

  String verificationCodeSentTo(String destination) =>
      text('verification_code_sent_to').replaceAll('{destination}', destination);

  String copiedToClipboardLabel(String label) =>
      text('copied_to_clipboard_label').replaceAll('{label}', label);

  String activeStatus(String status) =>
      text('active_status').replaceAll('{status}', status);

  String couponDiscountApplied(String discount) =>
      text('coupon_discount_applied').replaceAll('{discount}', discount);

  String payNowAmount(String amount) =>
      text('pay_now_amount').replaceAll('{amount}', amount);

  String weightKg(String weight) =>
      text('weight_kg').replaceAll('{weight}', weight);

  String locationsCount(int count) =>
      text('locations_count').replaceAll('{count}', count.toString());

  String applyProductsCount(int count) =>
      text('apply_products_count').replaceAll('{count}', count.toString());

  String activeFiltersCount(int count) =>
      text('active_filters_count').replaceAll('{count}', count.toString());

  String showingMatchesFor(String query) =>
      text('showing_matches_for').replaceAll('{query}', query);

  String homeUserName(String name) =>
      text('home_user_name').replaceAll('{name}', name);

  String categoryFreshStock(String category) =>
      text('category_fresh_stock').replaceAll('{category}', category);

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
    return AppLocalizations.load(locale);
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
