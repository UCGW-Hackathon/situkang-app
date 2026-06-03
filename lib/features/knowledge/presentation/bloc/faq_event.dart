part of 'faq_bloc.dart';

sealed class FaqEvent extends Equatable {
  const FaqEvent();

  @override
  List<Object?> get props => [];
}

class FetchFaqs extends FaqEvent {}
