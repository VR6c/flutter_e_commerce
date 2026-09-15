import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_e_commerce/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Supported locales include English and Khmer', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('km')));
    });

    test('Delegate supports en and km locales', () {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('km')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
    });

    test('All localizationsDelegates support km locale without error', () {
      for (final delegate in AppLocalizations.localizationsDelegates) {
        expect(delegate.isSupported(const Locale('km')), isTrue,
            reason: 'Delegate ${delegate.runtimeType} must support km locale');
      }
    });

    test('English translations return correct values', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.isKhmer, isFalse);
      expect(l10n.navHome, 'Home');
      expect(l10n.navProducts, 'Products');
      expect(l10n.navWishlist, 'Wishlist');
      expect(l10n.navProfile, 'Profile');
      expect(l10n.categories, 'Categories');
      expect(l10n.addToCart, 'Add to Cart');
      expect(l10n.cartTitle, 'Cart Page');
      expect(l10n.total, 'Total');
    });

    test('Khmer translations return correct values', () {
      final l10n = AppLocalizations(const Locale('km'));
      expect(l10n.isKhmer, isTrue);
      expect(l10n.navHome, 'ទំព័រដើម');
      expect(l10n.navProducts, 'ផលិតផល');
      expect(l10n.navWishlist, 'បញ្ជីចង់បាន');
      expect(l10n.navProfile, 'គណនី');
      expect(l10n.categories, 'ប្រភេទ');
      expect(l10n.addToCart, 'បន្ថែមទៅកន្ត្រក');
      expect(l10n.cartTitle, 'កន្ត្រកទំនិញ');
      expect(l10n.total, 'សរុបរួម');
    });

    test('Google Sans font files exist in assets/fonts/', () {
      final expectedFonts = [
        'assets/fonts/GoogleSans-Regular.ttf',
        'assets/fonts/GoogleSans-Medium.ttf',
        'assets/fonts/GoogleSans-SemiBold.ttf',
        'assets/fonts/GoogleSans-Bold.ttf',
        'assets/fonts/GoogleSans-Italic.ttf',
        'assets/fonts/GoogleSans-BoldItalic.ttf',
      ];
      for (final fontPath in expectedFonts) {
        final file = File(fontPath);
        expect(file.existsSync(), isTrue, reason: 'Missing font asset: $fontPath');
        expect(file.lengthSync(), greaterThan(100000), reason: 'Font file too small: $fontPath');
      }
    });
  });
}
