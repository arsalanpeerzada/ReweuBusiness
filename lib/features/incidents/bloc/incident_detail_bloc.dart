import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import 'ui_notice.dart';

// EVENTS
abstract class IncidentDetailEvent extends Equatable {
  const IncidentDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchIncidentDetailEvent extends IncidentDetailEvent {
  final int incidentId;

  const FetchIncidentDetailEvent(this.incidentId);

  @override
  List<Object?> get props => [incidentId];
}

class PostCommentEvent extends IncidentDetailEvent {
  final int incidentId;
  final String comment;

  const PostCommentEvent(this.incidentId, this.comment);

  @override
  List<Object?> get props => [incidentId, comment];
}

class ResolveIncidentEvent extends IncidentDetailEvent {
  final int incidentId;
  final String status;
  final String? summary;
  final bool sendVoucher;
  final double? voucherAmount;

  const ResolveIncidentEvent({
    required this.incidentId,
    required this.status,
    this.summary,
    this.sendVoucher = false,
    this.voucherAmount,
  });

  @override
  List<Object?> get props => [incidentId, status, summary, sendVoucher, voucherAmount];
}

// STATES
abstract class IncidentDetailState extends Equatable {
  const IncidentDetailState();

  @override
  List<Object?> get props => [];
}

class IncidentDetailInitial extends IncidentDetailState {}

class IncidentDetailLoading extends IncidentDetailState {}

class IncidentDetailLoaded extends IncidentDetailState {
  final IncidentDetailResponse incident;
  final bool actionInProgress;
  final UiNotice? notice;

  const IncidentDetailLoaded(
    this.incident, {
    this.actionInProgress = false,
    this.notice,
  });

  @override
  List<Object?> get props => [incident, actionInProgress, notice];
}

class IncidentDetailError extends IncidentDetailState {
  final String message;
  final ApiErrorKind kind;

  const IncidentDetailError(this.message, {this.kind = ApiErrorKind.unknown});

  @override
  List<Object?> get props => [message, kind];
}

// BLOC
/// Created per detail screen so one incident's state never shows on another.
class IncidentDetailBloc extends Bloc<IncidentDetailEvent, IncidentDetailState> {
  final IncidentRepository _repository;

  IncidentDetailBloc(this._repository) : super(IncidentDetailInitial()) {
    on<FetchIncidentDetailEvent>(_onFetchIncidentDetail);
    on<PostCommentEvent>(_onPostComment);
    on<ResolveIncidentEvent>(_onResolveIncident);
  }

  Future<void> _onFetchIncidentDetail(
    FetchIncidentDetailEvent event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final current = state;
    if (current is! IncidentDetailLoaded) emit(IncidentDetailLoading());
    try {
      final incident = await _repository.getIncidentDetail(event.incidentId);
      emit(IncidentDetailLoaded(incident));
    } on ApiException catch (e) {
      if (current is IncidentDetailLoaded) {
        emit(IncidentDetailLoaded(current.incident, notice: UiNotice(e.message)));
      } else {
        emit(IncidentDetailError(e.message, kind: e.kind));
      }
    } catch (_) {
      emit(IncidentDetailError('errors.unknown'.tr()));
    }
  }

  Future<void> _onPostComment(
    PostCommentEvent event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! IncidentDetailLoaded) return;
    emit(IncidentDetailLoaded(currentState.incident, actionInProgress: true));
    try {
      final updatedIncident = await _repository.addComment(
        event.incidentId,
        event.comment,
      );
      emit(IncidentDetailLoaded(
        updatedIncident,
        notice: UiNotice('incident_detail.note_added'.tr(), isError: false),
      ));
    } on ApiException catch (e) {
      emit(IncidentDetailLoaded(currentState.incident, notice: UiNotice(e.message)));
    } catch (_) {
      emit(IncidentDetailLoaded(currentState.incident, notice: UiNotice('errors.unknown'.tr())));
    }
  }

  Future<void> _onResolveIncident(
    ResolveIncidentEvent event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! IncidentDetailLoaded) return;
    emit(IncidentDetailLoaded(currentState.incident, actionInProgress: true));
    try {
      await _repository.updateStatus(
        event.incidentId,
        status: event.status,
        resolutionSummary: event.summary,
        sendVoucher: event.sendVoucher,
        voucherAmount: event.voucherAmount,
      );
      final updatedIncident = await _repository.getIncidentDetail(event.incidentId);
      emit(IncidentDetailLoaded(
        updatedIncident,
        notice: UiNotice(
          event.status == 'RESOLVED'
              ? 'incident_detail.resolved_notice'.tr()
              : 'incident_detail.status_updated'.tr(),
          isError: false,
        ),
      ));
    } on ApiException catch (e) {
      emit(IncidentDetailLoaded(currentState.incident, notice: UiNotice(e.message)));
    } catch (_) {
      emit(IncidentDetailLoaded(currentState.incident, notice: UiNotice('errors.unknown'.tr())));
    }
  }
}
