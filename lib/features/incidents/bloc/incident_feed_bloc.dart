import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';

// EVENTS
abstract class IncidentFeedEvent extends Equatable {
  const IncidentFeedEvent();

  @override
  List<Object?> get props => [];
}

class FetchIncidentsEvent extends IncidentFeedEvent {
  final int businessId;
  final int? branchId;
  final String status;

  const FetchIncidentsEvent({
    required this.businessId,
    this.branchId,
    this.status = 'OPEN',
  });

  @override
  List<Object?> get props => [businessId, branchId, status];
}

class FilterChangedEvent extends IncidentFeedEvent {
  final String status;

  const FilterChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class QuickAcknowledgeEvent extends IncidentFeedEvent {
  final int incidentId;

  const QuickAcknowledgeEvent(this.incidentId);

  @override
  List<Object?> get props => [incidentId];
}

// STATES
abstract class IncidentFeedState extends Equatable {
  const IncidentFeedState();

  @override
  List<Object?> get props => [];
}

class IncidentFeedInitial extends IncidentFeedState {}

class IncidentFeedLoading extends IncidentFeedState {}

class IncidentFeedLoaded extends IncidentFeedState {
  final List<IncidentListResponse> incidents;
  final String currentStatus;
  final int businessId;
  final int? branchId;

  const IncidentFeedLoaded({
    required this.incidents,
    required this.currentStatus,
    required this.businessId,
    this.branchId,
  });

  @override
  List<Object?> get props => [incidents, currentStatus, businessId, branchId];
}

class IncidentFeedError extends IncidentFeedState {
  final String message;

  const IncidentFeedError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class IncidentFeedBloc extends Bloc<IncidentFeedEvent, IncidentFeedState> {
  final IncidentRepository _repository;
  int _currentBusinessId = 0;
  int? _currentBranchId;
  String _currentStatus = 'OPEN';

  IncidentFeedBloc(this._repository) : super(IncidentFeedInitial()) {
    on<FetchIncidentsEvent>(_onFetchIncidents);
    on<FilterChangedEvent>(_onFilterChanged);
    on<QuickAcknowledgeEvent>(_onQuickAcknowledge);
  }

  Future<void> _onFetchIncidents(
    FetchIncidentsEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    _currentBusinessId = event.businessId;
    _currentBranchId = event.branchId;
    _currentStatus = event.status;
    emit(IncidentFeedLoading());
    try {
      final isCritical = event.status.toUpperCase() == 'CRITICAL';
      final isAll = event.status.toUpperCase() == 'ALL';
      final statusParam = (isCritical || isAll) ? null : event.status;

      final incidents = await _repository.getIncidents(
        businessId: event.businessId,
        branchId: event.branchId,
        status: statusParam,
      );

      final resultIncidents = isCritical
          ? incidents.where((i) => i.severity.toUpperCase() == 'CRITICAL').toList()
          : incidents;

      emit(IncidentFeedLoaded(
        incidents: resultIncidents,
        currentStatus: event.status,
        businessId: event.businessId,
        branchId: event.branchId,
      ));
    } catch (e) {
      emit(IncidentFeedError(e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    FilterChangedEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    _currentStatus = event.status;
    emit(IncidentFeedLoading());
    try {
      final isCritical = event.status.toUpperCase() == 'CRITICAL';
      final isAll = event.status.toUpperCase() == 'ALL';
      final statusParam = (isCritical || isAll) ? null : event.status;

      final incidents = await _repository.getIncidents(
        businessId: _currentBusinessId,
        branchId: _currentBranchId,
        status: statusParam,
      );

      final resultIncidents = isCritical
          ? incidents.where((i) => i.severity.toUpperCase() == 'CRITICAL').toList()
          : incidents;

      emit(IncidentFeedLoaded(
        incidents: resultIncidents,
        currentStatus: event.status,
        businessId: _currentBusinessId,
        branchId: _currentBranchId,
      ));
    } catch (e) {
      emit(IncidentFeedError(e.toString()));
    }
  }

  String get currentStatus => _currentStatus;

  Future<void> _onQuickAcknowledge(
    QuickAcknowledgeEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    try {
      await _repository.updateStatus(event.incidentId, status: 'ACKNOWLEDGED');
      final currentState = state;
      add(FilterChangedEvent(
        currentState is IncidentFeedLoaded
            ? currentState.currentStatus
            : _currentStatus,
      ));
    } catch (_) {}
  }
}
