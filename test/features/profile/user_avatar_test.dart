import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_e_commerce/features/profile/models/user_avatar_state.dart';
import 'package:flutter_e_commerce/features/profile/providers/user_avatar_provider.dart';
import 'package:flutter_e_commerce/features/profile/widgets/avatar_options_sheet.dart';
import 'package:flutter_e_commerce/shared/widgets/user_avatar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserAvatar Widget Tests', () {
    testWidgets('renders fallback initials when in default avatar state', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                radius: 30,
                name: 'Thary Vireak',
                showBorder: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('renders camera edit badge when showEditBadge is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                radius: 30,
                name: 'Thary Vireak',
                showEditBadge: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });
  });

  group('AvatarOptionsSheet Widget Tests', () {
    testWidgets('renders all options in AvatarOptionsSheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AvatarOptionsSheet(customerName: 'Thary Vireak'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile Picture & Avatar'), findsOneWidget);
      expect(find.text('Customize Avatar'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });
  });

  group('UserAvatarNotifier State Tests', () {
    test('transitions between avatar types correctly', () async {
      final notifier = UserAvatarNotifier(999);

      expect(notifier.state.type, AvatarType.defaultAvatar);
      expect(notifier.state.isDefault, isTrue);

      await notifier.setFluttermojiAvatar();
      expect(notifier.state.type, AvatarType.fluttermoji);
      expect(notifier.state.isFluttermoji, isTrue);

      await notifier.resetToDefault();
      expect(notifier.state.type, AvatarType.defaultAvatar);
      expect(notifier.state.isDefault, isTrue);
    });
  });
}
