import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:biotrack/core/api_client.dart';
import 'package:biotrack/features/auth/auth_provider.dart';
import 'package:biotrack/features/profile/edit_profile_screen.dart';

Widget _wrapped(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(ApiClient()),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('EditProfileScreen shows a password-change section with its own save button', (tester) async {
    await tester.pumpWidget(_wrapped(const EditProfileScreen()));
    expect(find.text('Alterar senha de login'), findsOneWidget);
    expect(find.text('Senha atual'), findsOneWidget);
    expect(find.text('Nova senha'), findsOneWidget);
    expect(find.text('Alterar senha'), findsOneWidget);
    expect(find.text('Salvar alterações'), findsOneWidget);
  });

  testWidgets('shows the new-password strength checklist as the field is typed', (tester) async {
    await tester.pumpWidget(_wrapped(const EditProfileScreen()));
    await tester.scrollUntilVisible(find.text('Nova senha'), 300, scrollable: find.byType(Scrollable).last);
    final newPasswordField = find.byType(TextField).last;
    await tester.enterText(newPasswordField, 'Senha@123');
    await tester.pump();
    expect(find.text('Letra maiúscula'), findsOneWidget);
    expect(find.text('Caractere especial (!@#\$...)'), findsOneWidget);
  });

  testWidgets('rejects changing password without the current password filled in', (tester) async {
    await tester.pumpWidget(_wrapped(const EditProfileScreen()));
    await tester.scrollUntilVisible(find.text('Alterar senha'), 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Alterar senha'));
    await tester.pump();
    expect(find.text('Informe sua senha atual.'), findsOneWidget);
  });
}
