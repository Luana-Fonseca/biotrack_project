import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:biotrack/core/api_client.dart';
import 'package:biotrack/core/theme.dart';
import 'package:biotrack/core/theme_provider.dart';
import 'package:biotrack/features/auth/auth_provider.dart';
import 'package:biotrack/features/profile/profile_screen.dart';

Widget _wrapped(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(ApiClient())),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      home: child,
    ),
  );
}

void main() {
  testWidgets('ProfileScreen shows Editar perfil and Modo escuro, not Notificações/Idioma', (tester) async {
    await tester.pumpWidget(_wrapped(const ProfileScreen()));
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Modo escuro'), findsOneWidget);
    expect(find.text('Notificações'), findsNothing);
    expect(find.text('Idioma'), findsNothing);
  });

  testWidgets('toggling Modo escuro flips ThemeProvider.isDark', (tester) async {
    late ThemeProvider themeProvider;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiClient())),
          ChangeNotifierProvider(create: (context) {
            themeProvider = ThemeProvider();
            return themeProvider;
          }),
        ],
        child: Builder(builder: (context) {
          return Consumer<ThemeProvider>(builder: (context, tp, _) {
            return MaterialApp(
              theme: buildAppTheme(),
              darkTheme: buildAppDarkTheme(),
              themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
              home: const ProfileScreen(),
            );
          });
        }),
      ),
    );

    expect(themeProvider.isDark, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(themeProvider.isDark, isTrue);
  });
}
