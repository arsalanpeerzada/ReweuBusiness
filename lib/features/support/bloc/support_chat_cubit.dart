import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/support_config.dart';
import '../../../data/repositories/support_repository.dart';

abstract class SupportChatState extends Equatable {
  const SupportChatState();

  @override
  List<Object?> get props => [];
}

class SupportChatInitial extends SupportChatState {}

class SupportChatLoading extends SupportChatState {
  final SupportConfig? config;
  const SupportChatLoading({this.config});

  @override
  List<Object?> get props => [config];
}

class SupportChatLoaded extends SupportChatState {
  final List<SupportMessage> messages;
  final SupportConfig? config;
  final bool isSending;
  final bool chatUnavailable;
  final String? errorBanner;

  const SupportChatLoaded({
    required this.messages,
    this.config,
    this.isSending = false,
    this.chatUnavailable = false,
    this.errorBanner,
  });

  SupportChatLoaded copyWith({
    List<SupportMessage>? messages,
    SupportConfig? config,
    bool? isSending,
    bool? chatUnavailable,
    String? errorBanner,
    bool clearError = false,
  }) {
    return SupportChatLoaded(
      messages: messages ?? this.messages,
      config: config ?? this.config,
      isSending: isSending ?? this.isSending,
      chatUnavailable: chatUnavailable ?? this.chatUnavailable,
      errorBanner: clearError ? null : (errorBanner ?? this.errorBanner),
    );
  }

  @override
  List<Object?> get props => [messages, config, isSending, chatUnavailable, errorBanner];
}

class SupportChatCubit extends Cubit<SupportChatState> {
  final SupportRepository repository;
  final int? incidentId;

  SupportChatCubit({
    required this.repository,
    this.incidentId,
  }) : super(SupportChatInitial());

  Future<void> load({bool showSpinner = true}) async {
    final cached = repository.getCachedSupportConfig();
    if (showSpinner) {
      emit(SupportChatLoading(config: cached));
    }

    final config = await repository.getSupportConfig(forceRefresh: true);

    try {
      final messages = await repository.getMessages(incidentId: incidentId);
      emit(SupportChatLoaded(
        messages: messages,
        config: config,
      ));
    } on ApiException catch (e) {
      final isUnavailable = e.kind == ApiErrorKind.notFound || e.statusCode == 501;
      emit(SupportChatLoaded(
        messages: const [],
        config: config,
        chatUnavailable: isUnavailable,
        errorBanner: isUnavailable ? null : e.message,
      ));
    } catch (e) {
      emit(SupportChatLoaded(
        messages: const [],
        config: config,
        errorBanner: e.toString(),
      ));
    }
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final current = state;
    final currentMessages = current is SupportChatLoaded ? current.messages : <SupportMessage>[];
    final currentConfig = current is SupportChatLoaded ? current.config : repository.getCachedSupportConfig();

    emit(SupportChatLoaded(
      messages: currentMessages,
      config: currentConfig,
      isSending: true,
    ));

    try {
      final sent = await repository.sendMessage(
        message: trimmed,
        incidentId: incidentId,
      );
      emit(SupportChatLoaded(
        messages: [...currentMessages, sent],
        config: currentConfig,
        isSending: false,
      ));
      return true;
    } on ApiException catch (e) {
      final isUnavailable = e.kind == ApiErrorKind.notFound || e.statusCode == 501;
      emit(SupportChatLoaded(
        messages: currentMessages,
        config: currentConfig,
        isSending: false,
        chatUnavailable: isUnavailable,
        errorBanner: e.message,
      ));
      return false;
    } catch (e) {
      emit(SupportChatLoaded(
        messages: currentMessages,
        config: currentConfig,
        isSending: false,
        errorBanner: e.toString(),
      ));
      return false;
    }
  }
}
