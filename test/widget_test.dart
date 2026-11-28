import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/features/contributions/presentation/register/register_contribution_view_model.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/welcome_page.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';

void main() {
  testWidgets('the welcome page presents Pozzo and its two ways in', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: PozzoTheme.light(), home: const WelcomePage()));

    expect(find.text('Tu junta, sin cuaderno ni capturas'), findsOneWidget);
    expect(find.text('Continuar con mi celular'), findsOneWidget);
    expect(find.text('Tengo un código de invitación'), findsOneWidget);
  });

  test('amounts are shown in soles as the design does', () {
    expect(Formats.soles(2400), 'S/ 2,400');
    expect(Formats.soles(150.5), 'S/ 150.50');
    expect(Formats.soles(1234567.89), 'S/ 1,234,567.89');
  });

  test('a Peruvian mobile number has nine digits and starts with 9', () {
    expect(PhoneNumbers.isValid('999000123'), isTrue);
    expect(PhoneNumbers.isValid('899000123'), isFalse);
    expect(PhoneNumbers.display('+51999000123'), '+51 999 000 123');
  });

  test('invitation codes are cleaned and shown in two parts', () {
    final code = InvitationCodes.normalize('jb-7k4m');
    expect(code, 'JB7K4M');
    expect(InvitationCodes.display(code), 'JB-7K4M');
    expect(InvitationCodes.isComplete(code), isTrue);
  });

  test('the payee of a receipt matches even when the wallet hides part of the name', () {
    expect(namesMatch('Anna W*', 'Anna Weber'), isTrue);
    expect(namesMatch('ANNA WEBER', 'Anna Weber'), isTrue);
    expect(namesMatch('Rosa Medina', 'Anna Weber'), isFalse);
  });
}
