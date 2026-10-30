import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/incident_analytics.dart';
import '../../../data/repositories/incident_repository.dart';

enum AnalyticsPeriod { days7, days30, days90 }

extension AnalyticsPeriodX on AnalyticsPeriod {
  int get days => switch (this) {
        AnalyticsPeriod.days7 => 7,
        AnalyticsPeriod.days30 => 30,
        AnalyticsPeriod.days90 => 90,
      };
}

class IncidentAnalyticsState extends Equatable {
  final AnalyticsPeriod period;
  final bool isLoading;
  final IncidentAnalytics? data;
  final String? error;

  const IncidentAnalyticsState({
    this.period = AnalyticsPeriod.days30,
    this.isLoading = false,
    this.data,
    this.error,
  });

  @override
  List<Object?> get props => [period, isLoading, data, error];
}

class IncidentAnalyticsCubit extends Cubit<IncidentAnalyticsState> {
  final IncidentRepository _repository;
  final int businessId;

  IncidentAnalyticsCubit(this._repository, {required this.businessId})
      : super(const IncidentAnalyticsState());

  Future<void> load([AnalyticsPeriod? period]) async {
    final p = period ?? state.period;
    emit(IncidentAnalyticsState(period: p, isLoading: true, data: state.data));
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: p.days - 1));
    try {
      final data = await _repository.getAnalytics(
        businessId: businessId,
        startDate: start,
        endDate: now,
      );
      emit(IncidentAnalyticsState(period: p, data: data));
    } on ApiException catch (e) {
      emit(IncidentAnalyticsState(period: p, error: e.message));
    } catch (_) {
      emit(IncidentAnalyticsState(period: p, error: 'errors.unknown'.tr()));
    }
  }
}
