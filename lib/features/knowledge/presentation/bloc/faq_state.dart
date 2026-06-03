part of 'faq_bloc.dart';

enum FaqStatus { initial, loading, success, error }

class FaqState extends Equatable {
  const FaqState({
    this.status = FaqStatus.initial,
    this.faqs = const <Faq>[],
    this.failure,
  });

  final FaqStatus status;
  final List<Faq> faqs;
  final Failure? failure;

  FaqState copyWith({
    FaqStatus? status,
    List<Faq>? faqs,
    Failure? failure,
  }) {
    return FaqState(
      status: status ?? this.status,
      faqs: faqs ?? this.faqs,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, faqs, failure];
}
