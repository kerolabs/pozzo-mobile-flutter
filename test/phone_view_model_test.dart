
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/auth_repository.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/phone_view_model.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  int requestCount = 0;
  String? requestedPhone;

  final completer = Completer<CodeRequest>();

  @override
  Future<CodeRequest> requestCode(String phoneNumber) {
    requestCount++;
    requestedPhone = phoneNumber;
    return completer.future;
  }
}

void main() {
  late FakeAuthRepository repository;
  late PhoneViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();

    viewModel = PhoneViewModel(
      requestCode: RequestCodeUseCase(
        repository: repository,
      ),
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('PhoneViewModel', () {
    test('initial state does not allow sending a code', () {
      expect(viewModel.state.phone, isEmpty);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.canSend, isFalse);
      expect(viewModel.state.errorMessage, isNull);
    });

    test('cleans a phone number with country prefix', () {
      viewModel.onPhoneChanged('+51 999 000 123');

      expect(viewModel.state.phone, '999000123');
      expect(viewModel.state.canSend, isTrue);
    });

    test('invalid phone does not request an SMS code', () async {
      viewModel.onPhoneChanged('123456789');

      final result = await viewModel.sendCode();

      expect(result, isNull);
      expect(repository.requestCount, 0);
      expect(viewModel.state.errorMessage, isNotNull);
      expect(viewModel.state.isLoading, isFalse);
    });

    test('valid phone successfully requests an SMS code', () async {
      viewModel.onPhoneChanged('999000123');

      final pending = viewModel.sendCode();

      expect(viewModel.state.isLoading, isTrue);
      expect(viewModel.state.canSend, isFalse);
      expect(repository.requestCount, 1);
      expect(repository.requestedPhone, '999000123');

      final now = DateTime.now();

      final request = CodeRequest(
        phoneNumber: '999000123',
        expiresAt: now.add(const Duration(minutes: 5)),
        resendAvailableAt: now.add(
          const Duration(seconds: 60),
        ),
      );

      repository.completer.complete(request);

      final result = await pending;

      expect(result, same(request));
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.errorMessage, isNull);
    });

    test('does not send duplicate SMS requests', () async {
      viewModel.onPhoneChanged('999000123');

      final firstRequest = viewModel.sendCode();

      final secondRequest = await viewModel.sendCode();

      expect(secondRequest, isNull);
      expect(repository.requestCount, 1);
      expect(viewModel.state.isLoading, isTrue);

      final now = DateTime.now();

      repository.completer.complete(
        CodeRequest(
          phoneNumber: '999000123',
          expiresAt: now.add(const Duration(minutes: 5)),
          resendAvailableAt: now.add(
            const Duration(seconds: 60),
          ),
        ),
      );

      await firstRequest;

      expect(repository.requestCount, 1);
      expect(viewModel.state.isLoading, isFalse);
    });

    test('handles request failures and restores loading state', () async {
      viewModel.onPhoneChanged('999000123');

      final pending = viewModel.sendCode();

      repository.completer.completeError(
        const AppException('No se pudo enviar el código.'),
      );

      final result = await pending;

      expect(result, isNull);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.canSend, isTrue);

      expect(
        viewModel.state.errorMessage,
        'No se pudo enviar el código.',
      );
    });

    test('changing the phone clears the previous error', () async {
      viewModel.onPhoneChanged('123');

      await viewModel.sendCode();

      expect(viewModel.state.errorMessage, isNotNull);

      viewModel.onPhoneChanged('999000123');

      expect(viewModel.state.errorMessage, isNull);
      expect(viewModel.state.canSend, isTrue);
    });
  });
}
