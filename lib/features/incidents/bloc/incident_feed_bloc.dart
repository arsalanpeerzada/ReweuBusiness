import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';
import 'ui_notice.dart';

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

class BranchChangedEvent extends IncidentFeedEvent {
  final int? branchId;

  const BranchChangedEvent(this.branchId);

  @override
  List<Object?> get props => [branchId];
}

class RefreshIncidentsEvent extends IncidentFeedEvent {
  /// Completed when the refresh finishes, so pull-to-refresh can stop
  /// spinning even if the data did not change.
  final Completer<void>? completer;

  const RefreshIncidentsEvent({this.completer});
}

class LoadMoreIncidentsEvent extends IncidentFeedEvent {
  const LoadMoreIncidentsEvent();
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
  final bool hasMore;
  final bool isLoadingMore;
  final bool fromCache;
  final UiNotice? notice;

  const IncidentFeedLoaded({
    required this.incidents,
    required this.currentStatus,
    required this.businessId,
    this.branchId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.fromCache = false,
    this.notice,
  });

  IncidentFeedLoaded copyWith({
    List<IncidentListResponse>? incidents,
    bool? hasMore,
    bool? isLoadingMore,
    bool? fromCache,
    UiNotice? notice,
  }) {
    return IncidentFeedLoaded(
      incidents: incidents ?? this.incidents,
      currentStatus: currentStatus,
      businessId: businessId,
      branchId: branchId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      fromCache: fromCache ?? this.fromCache,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [
        incidents,
        currentStatus,
        businessId,
        branchId,
        hasMore,
        isLoadingMore,
        fromCache,
        notice,
      ];
}

class IncidentFeedError extends IncidentFeedState {
  final String message;
  final ApiErrorKind kind;

  const IncidentFeedError(this.message, {this.kind = ApiErrorKind.unknown});

  bool get isAccessDenied => kind == ApiErrorKind.forbidden;

  @override
  List<Object?> get props => [message, kind];
}

// BLOC
class IncidentFeedBloc extends Bloc<IncidentFeedEvent, IncidentFeedState> {
  final IncidentRepository _repository;
  int _currentBusinessId = 0;
  int? _currentBranchId;
  String _currentStatus = 'OPEN';
  int _nextPage = 0;

  /// The backend has no severity filter, so the Critical tab filters pages
  /// client-side and reads ahead up to this many pages to fill the list.
  static const int maxCriticalReadAhead = 5;

  IncidentFeedBloc(this._repository) : super(IncidentFeedInitial()) {
    on<FetchIncidentsEvent>(_onFetchIncidents);
    on<FilterChangedEvent>(_onFilterChanged);
    on<BranchChangedEvent>(_onBranchChanged);
    on<RefreshIncidentsEvent>(_onRefresh);
    on<LoadMoreIncidentsEvent>(_onLoadMore);
    on<QuickAcknowledgeEvent>(_onQuickAcknowledge);
  }

  String get currentStatus => _currentStatus;
  int? get currentBranchId => _currentBranchId;

  bool get _isCritical => _currentStatus.toUpperCase() == 'CRITICAL';

  String? get _statusParam {
    final upper = _currentStatus.toUpperCase();
    return (upper == 'CRITICAL' || upper == 'ALL') ? null : _currentStatus;
  }

  List<IncidentListResponse> _applyFilter(List<IncidentListResponse> items) => _isCritical
      ? items.where((i) => i.severity.toUpperCase() == 'CRITICAL').toList()
      : items;

  Future<void> _onFetchIncidents(
    FetchIncidentsEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    _currentBusinessId = event.businessId;
    _currentBranchId = event.branchId;
    _currentStatus = event.status;
    await _loadFirstPage(emit);
  }

  Future<void> _onFilterChanged(
    FilterChangedEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    _currentStatus = event.status;
    await _loadFirstPage(emit);
  }

  Future<void> _onBranchChanged(
    BranchChangedEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    _currentBranchId = event.branchId;
    await _loadFirstPage(emit);
  }

  Future<void> _onRefresh(
    RefreshIncidentsEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    try {
      await _loadFirstPage(emit, showSkeleton: state is! IncidentFeedLoaded);
    } finally {
      if (event.completer?.isCompleted == false) event.completer!.complete();
    }
  }

  Future<void> _loadFirstPage(Emitter<IncidentFeedState> emit, {bool showSkeleton = true}) async {
    if (_currentBusinessId <= 0) {
      emit(IncidentFeedError('errors.no_business'.tr(), kind: ApiErrorKind.forbidden));
      return;
    }
    final previous = state;
    if (showSkeleton) emit(IncidentFeedLoading());
    try {
      _nextPage = 0;
      final collected = <IncidentListResponse>[];
      var hasMore = true;
      var fromCache = false;
      var pagesRead = 0;

      do {
        final page = await _repository.getIncidents(
          businessId: _currentBusinessId,
          branchId: _currentBranchId,
          status: _statusParam,
          page: _nextPage,
        );
        _nextPage++;
        pagesRead++;
        collected.addAll(_applyFilter(page.items));
        hasMore = !page.isLast && !page.fromCache;
        fromCache = page.fromCache;
      } while (_isCritical && hasMore && collected.length < 10 && pagesRead < maxCriticalReadAhead);

      emit(IncidentFeedLoaded(
        incidents: collected,
        currentStatus: _currentStatus,
        businessId: _currentBusinessId,
        branchId: _currentBranchId,
        hasMore: hasMore,
        fromCache: fromCache,
      ));
    } on ApiException catch (e) {
      // A failed background refresh keeps the list on screen.
      if (!showSkeleton && previous is IncidentFeedLoaded) {
        emit(previous.copyWith(notice: UiNotice(e.message)));
      } else {
        emit(IncidentFeedError(e.message, kind: e.kind));
      }
    } catch (_) {
      emit(IncidentFeedError('errors.unknown'.tr()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreIncidentsEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    final current = state;
    if (current is! IncidentFeedLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.getIncidents(
        businessId: _currentBusinessId,
        branchId: _currentBranchId,
        status: _statusParam,
        page: _nextPage,
      );
      _nextPage++;
      final seen = current.incidents.map((i) => i.id).toSet();
      final more = _applyFilter(page.items).where((i) => !seen.contains(i.id));
      emit(current.copyWith(
        incidents: [...current.incidents, ...more],
        hasMore: !page.isLast,
        isLoadingMore: false,
      ));
    } on ApiException catch (e) {
      emit(current.copyWith(isLoadingMore: false, notice: UiNotice(e.message)));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false, notice: UiNotice('errors.unknown'.tr())));
    }
  }

  Future<void> _onQuickAcknowledge(
    QuickAcknowledgeEvent event,
    Emitter<IncidentFeedState> emit,
  ) async {
    try {
      await _repository.updateStatus(event.incidentId, status: 'ACKNOWLEDGED');
      final current = state;
      if (current is IncidentFeedLoaded) {
        emit(current.copyWith(
          notice: UiNotice('incidents.acknowledged_notice'.tr(), isError: false),
        ));
      }
      await _loadFirstPage(emit, showSkeleton: false);
    } on ApiException catch (e) {
      final current = state;
      if (current is IncidentFeedLoaded) {
        emit(current.copyWith(notice: UiNotice(e.message)));
      }
    } catch (_) {
      final current = state;
      if (current is IncidentFeedLoaded) {
        emit(current.copyWith(notice: UiNotice('errors.unknown'.tr())));
      }
    }
  }
}
