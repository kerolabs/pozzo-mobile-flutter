import 'package:flutter_test/flutter_test.dart';
import 'package:pozzo/main.dart';

void main() {
  testWidgets('the welcome page presents Pozzo and its two ways in', (tester) async {
    await tester.pumpWidget(const PozzoApp());

    expect(find.text('Tu junta, sin cuaderno ni capturas'), findsOneWidget);
    expect(find.text('Continuar con mi celular'), findsOneWidget);
    expect(find.text('Tengo un código de invitación'), findsOneWidget);
  });
}
