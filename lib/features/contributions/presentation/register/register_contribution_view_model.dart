import 'dart:typed_data';

import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';

enum RegisterStep { instructions, capture, review, result }

/// The data of the receipt as the member writes it.
class ReceiptForm {
  ReceiptForm({
    this.amount = '',
    DateTime? paidAt,
    this.payeeName = '',
    this.operationNumber = '',
    this.source = ReceiptSource.yape,
  }) : paidAt = paidAt ?? Formats.today();

  final String amount;
  final DateTime paidAt;
  final String payeeName;
  final String operationNumber;
  final ReceiptSource source;

  double? get amountValue {
    final value = double.tryParse(amount.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  bool get isComplete => amountValue != null && payeeName.trim().isNotEmpty && operationNumber.length >= 4;

  ReceiptForm copyWith({
    String? amount,
    DateTime? paidAt,
    String? payeeName,
    String? operationNumber,
    ReceiptSource? source,
  }) {
    return ReceiptForm(
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      payeeName: payeeName ?? this.payeeName,
      operationNumber: operationNumber ?? this.operationNumber,
      source: source ?? this.source,
    );
  }
}

class RegisterContributionState {
  RegisterContributionState({
    this.cycle,
    this.period,
    this.step = RegisterStep.instructions,
    ReceiptForm? form,
    this.image,
    this.isSaving = false,
    this.errorMessage,
    this.result,
    this.imageNotKept = false,
  }) : form = form ?? ReceiptForm();

  final Cycle? cycle;
  final Period? period;
  final RegisterStep step;
  final ReceiptForm form;

  /// The photo of the receipt, kept with the contribution once it is registered.
  final Uint8List? image;
  final bool isSaving;
  final String? errorMessage;
  final Contribution? result;
  final bool imageNotKept;

  /// The receipt matches what the group expects: the amount, a date before the cutoff and the payee.
  bool get matchesExpected {
    final cycle = this.cycle;
    final period = this.period;
    final amount = form.amountValue;
    if (cycle == null || period == null || amount == null) return false;
    return (amount - period.myAmount).abs() < 0.005 &&
        !form.paidAt.isAfter(period.cutoffDate) &&
        namesMatch(form.payeeName, cycle.payeeName);
  }

  RegisterContributionState copyWith({
    Cycle? cycle,
    Period? period,
    RegisterStep? step,
    ReceiptForm? form,
    Uint8List? image,
    bool clearImage = false,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    Contribution? result,
    bool? imageNotKept,
  }) {
    return RegisterContributionState(
      cycle: cycle ?? this.cycle,
      period: period ?? this.period,
      step: step ?? this.step,
      form: form ?? this.form,
      image: clearImage ? null : image ?? this.image,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      imageNotKept: imageNotKept ?? this.imageNotKept,
    );
  }
}

/// True when every word of [expected] is in [found], ignoring accents and case. A word that ends in
/// "*" in the receipt ("Anna W*") matches the start of the expected word, as Yape and Plin hide names.
bool namesMatch(String found, String expected) {
  List<String> words(String value) {
    const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
    var text = value.toLowerCase();
    for (final accent in accents.entries) {
      text = text.replaceAll(accent.key, accent.value);
    }
    return text
        .replaceAll(RegExp(r'[^a-z0-9* ]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  final foundWords = words(found);
  return words(expected).every(
    (expectedWord) => foundWords.any(
      (word) =>
          word == expectedWord ||
          (word.endsWith('*') && expectedWord.startsWith(word.substring(0, word.length - 1))),
    ),
  );
}

/// C2: the member registers their contribution with the data of the receipt and its photo.
class RegisterContributionViewModel extends ViewModel<RegisterContributionState> {
  RegisterContributionViewModel({
    required this.getPotState,
    required this.registerContribution,
    required this.attachReceiptImage,
    required this.groupId,
  }) : super(RegisterContributionState()) {
    load();
  }

  final GetPotStateUseCase getPotState;
  final RegisterContributionUseCase registerContribution;
  final AttachReceiptImageUseCase attachReceiptImage;
  final String groupId;

  Future<void> load() async {
    emit(state.copyWith(clearError: true));
    try {
      final (cycle, period) = await getPotState.execute(groupId);
      emit(state.copyWith(cycle: cycle, period: period));
    } catch (error) {
      emit(state.copyWith(errorMessage: userMessageOf(error)));
    }
  }

  void goTo(RegisterStep step) => emit(state.copyWith(step: step, clearError: true));

  /// Goes back one step; false when the page itself must close.
  bool back() {
    if (state.step == RegisterStep.instructions || state.step == RegisterStep.result) return false;
    goTo(RegisterStep.values[state.step.index - 1]);
    return true;
  }

  /// The photo of the receipt: the member writes its data and the photo is kept with the contribution.
  void onImageChosen(Uint8List image) {
    emit(
      state.copyWith(
        image: image,
        step: RegisterStep.review,
        form: ReceiptForm(payeeName: state.cycle?.payeeName ?? ''),
        clearError: true,
      ),
    );
  }

  void enterManually() => emit(
        state.copyWith(
          step: RegisterStep.review,
          form: ReceiptForm(payeeName: state.cycle?.payeeName ?? ''),
          clearImage: true,
          clearError: true,
        ),
      );

  void onAmountChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    emit(state.copyWith(form: state.form.copyWith(amount: cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned)));
  }

  void onPaidAtChanged(DateTime value) => emit(state.copyWith(form: state.form.copyWith(paidAt: value)));

  void onPayeeChanged(String value) =>
      emit(state.copyWith(form: state.form.copyWith(payeeName: value.length > 120 ? value.substring(0, 120) : value)));

  void onOperationChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    emit(state.copyWith(form: state.form.copyWith(operationNumber: cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned)));
  }

  void onSourceChanged(ReceiptSource value) => emit(state.copyWith(form: state.form.copyWith(source: value)));

  Future<void> confirm() async {
    final period = state.period;
    final amount = state.form.amountValue;
    if (period == null || amount == null || !state.form.isComplete || state.isSaving) return;
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final contribution = await registerContribution.execute(
        period.id,
        ReceiptData(
          operationNumber: state.form.operationNumber,
          payerName: null,
          payeeName: state.form.payeeName,
          amount: amount,
          paidAt: state.form.paidAt,
          source: state.form.source,
        ),
      );
      var result = contribution;
      var imageNotKept = false;
      final image = state.image;
      if (image != null) {
        try {
          result = await attachReceiptImage.execute(contribution.id, image);
        } catch (_) {
          // The contribution is registered even if its photo could not be kept.
          imageNotKept = true;
        }
      }
      emit(state.copyWith(isSaving: false, result: result, imageNotKept: imageNotKept, step: RegisterStep.result));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: userMessageOf(error)));
    }
  }
}
