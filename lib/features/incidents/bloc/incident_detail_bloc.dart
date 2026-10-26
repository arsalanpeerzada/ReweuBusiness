import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';

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

  const IncidentDetailLoaded(this.incident);

  @override
  List<Object?> get props => [incident];
}

class IncidentDetailActionInProgress extends IncidentDetailState {
  final IncidentDetailResponse incident;

  const IncidentDetailActionInProgress(this.incident);

  @override
  List<Object?> get props => [incident];
}

class IncidentDetailError extends IncidentDetailState {
  final String message;

  const IncidentDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
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
    emit(IncidentDetailLoading());
    try {
      final incident = await _repository.getIncidentDetail(event.incidentId);
      emit(IncidentDetailLoaded(incident));
    } catch (e) {
      emit(IncidentDetailError(e.toString()));
    }
  }

  Future<void> _onPostComment(
    PostCommentEvent event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is IncidentDetailLoaded) {
      emit(IncidentDetailActionInProgress(currentState.incident));
      try {
        final updatedIncident = await _repository.addComment(
          event.incidentId,
          event.comment,
        );
        emit(IncidentDetailLoaded(updatedIncident));
      } catch (e) {
        emit(IncidentDetailLoaded(currentState.incident));
      }
    }
  }

  Future<void> _onResolveIncident(
    ResolveIncidentEvent event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is IncidentDetailLoaded) {
      emit(IncidentDetailActionInProgress(currentState.incident));
      try {
        await _repository.updateStatus(
          event.incidentId,
          status: event.status,
          resolutionSummary: event.summary,
          sendVoucher: event.sendVoucher,
          voucherAmount: event.voucherAmount,
        );
        // Refresh detail
        final updatedIncident = await _repository.getIncidentDetail(event.incidentId);
        emit(IncidentDetailLoaded(updatedIncident));
      } catch (e) {
        emit(IncidentDetailLoaded(currentState.incident));
      }
    }
  }
}
