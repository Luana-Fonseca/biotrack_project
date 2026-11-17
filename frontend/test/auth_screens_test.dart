import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:biotrack/core/api_client.dart';
import 'package:biotrack/features/auth/auth_provider.dart';
import 'package:biotrack/features/auth/landing_screen.dart';
import 'package:biotrack/features/auth/login_screen.dart';
import 'package:biotrack/features/auth/register_screen.dart';

Widget _withAuth(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(ApiClient()),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('LandingScreen renders hero copy and both CTAs', (tester) async {
    await tester.pumpWidget(_withAuth(const LandingScreen()));
    expect(find.text('BioTrack'), findsOneWidget);
    expect(find.text('Criar conta grátis'), findsOneWidget);
    expect(find.text('Já tenho conta'), findsOneWidget);
  });

  testWidgets('LoginScreen renders email/password fields and submit button', (tester) async {
    await tester.pumpWidget(_withAuth(const LoginScreen()));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Entrar'), findsWidgets);
  });

  testWidgets('RegisterScreen renders the registration form fields', (tester) async {
    await tester.pumpWidget(_withAuth(const RegisterScreen()));
    expect(find.text('Criar sua conta'), findsOneWidget);
    expect(find.text('NOME COMPLETO'), findsOneWidget);
    expect(find.text('CIDADE'), findsOneWidget);
    expect(find.text('NASCIMENTO'), findsOneWidget);
    expect(find.text('PROFISSÃO'), findsOneWidget);
    expect(find.text('Selecione sua profissão'), findsOneWidget);
    expect(find.text('Criar conta e continuar'), findsOneWidget);
  });

  testWidgets('tapping the profession field opens a picker with the profession list', (tester) async {
    await tester.pumpWidget(_withAuth(const RegisterScreen()));
    await tester.scrollUntilVisible(find.text('Selecione sua profissão'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Selecione sua profissão'));
    await tester.pumpAndSettle();
    expect(find.text('Motorista'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Estudante'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Estudante'), findsOneWidget);
  });

  testWidgets('RegisterScreen shows the live password strength checklist', (tester) async {
    await tester.pumpWidget(_withAuth(const RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(2), 'Senha@123');
    await tester.pump();
    expect(find.text('Mínimo de 8 caracteres'), findsOneWidget);
    expect(find.text('Letra maiúscula'), findsOneWidget);
    expect(find.text('Letra minúscula'), findsOneWidget);
    expect(find.text('Número'), findsOneWidget);
    expect(find.text('Caractere especial (!@#\$...)'), findsOneWidget);
  });

  testWidgets('RegisterScreen rejects a weak password before checking the terms checkbox', (tester) async {
    await tester.pumpWidget(_withAuth(const RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(2), 'fraca');
    await tester.scrollUntilVisible(find.text('Criar conta e continuar'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Criar conta e continuar'));
    await tester.pump();
    expect(find.text('A senha precisa ter maiúscula, minúscula, número e caractere especial.'), findsOneWidget);
  });

  testWidgets('RegisterScreen requires accepting the terms checkbox once the password is strong', (tester) async {
    await tester.pumpWidget(_withAuth(const RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(2), 'Senha@123');
    await tester.scrollUntilVisible(find.text('Criar conta e continuar'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Criar conta e continuar'));
    await tester.pump();
    expect(find.text('É preciso concordar com os Termos de Uso e a Política de Privacidade.'), findsOneWidget);
  });

  testWidgets('typing in LoginScreen fields does not throw (regression check for TextEditingController lifecycle)', (tester) async {
    await tester.pumpWidget(_withAuth(const LoginScreen()));
    await tester.enterText(find.byType(TextField).first, 'teste@example.com');
    await tester.enterText(find.byType(TextField).last, 'Senha@123');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
