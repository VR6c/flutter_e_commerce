import 'dart:convert';
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
        expect(
          delegate.isSupported(const Locale('km')),
          isTrue,
          reason: 'Delegate ${delegate.runtimeType} must support km locale',
        );
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
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing font asset: $fontPath',
        );
        expect(
          file.lengthSync(),
          greaterThan(100000),
          reason: 'Font file too small: $fontPath',
        );
      }
    });

    test(
      'en.json and km.json files exist, parse correctly, and have 100% key parity',
      () {
        final enFile = File('assets/translations/en.json');
        final kmFile = File('assets/translations/km.json');

        expect(enFile.existsSync(), isTrue);
        expect(kmFile.existsSync(), isTrue);

        final enData =
            json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
        final kmData =
            json.decode(kmFile.readAsStringSync()) as Map<String, dynamic>;

        expect(enData.isNotEmpty, isTrue);
        expect(kmData.isNotEmpty, isTrue);

        final enKeys = enData.keys.toSet();
        final kmKeys = kmData.keys.toSet();

        final missingInKm = enKeys.difference(kmKeys);
        final missingInEn = kmKeys.difference(enKeys);

        expect(
          missingInKm,
          isEmpty,
          reason: 'Keys in en.json but missing in km.json: $missingInKm',
        );
        expect(
          missingInEn,
          isEmpty,
          reason: 'Keys in km.json but missing in en.json: $missingInEn',
        );
        expect(enKeys.length, kmKeys.length);
      },
    );

    test(
      'Parameterized translation helpers substitute placeholders properly',
      () {
        final enL10n = AppLocalizations(const Locale('en'));
        final kmL10n = AppLocalizations(const Locale('km'));

        expect(enL10n.payNowAmount('25.00'), 'Pay Now · \$25.00');
        expect(kmL10n.payNowAmount('25.00'), 'ទូទាត់ឥឡូវនេះ · \$25.00');

        expect(enL10n.greetingUser('Alex'), 'Hi, Alex 👋');
        expect(kmL10n.greetingUser('Alex'), 'សួស្តី, Alex 👋');

        expect(enL10n.activeFiltersCount(3), '3 Active');
        expect(kmL10n.activeFiltersCount(3), '3 កំពុងប្រើ');

        expect(
          enL10n.activeStatus('Default Initials'),
          'Active: Default Initials',
        );
        expect(
          kmL10n.activeStatus('អក្សរកាត់លំនាំដើម'),
          'កំពុងប្រើ: អក្សរកាត់លំនាំដើម',
        );
      },
    );
  });
}
