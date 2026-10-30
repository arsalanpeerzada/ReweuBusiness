import 'package:equatable/equatable.dart';

/// One-off message for the UI to show as a snackbar. [id] changes on every
/// new notice so listeners fire even when the text repeats.
class UiNotice extends Equatable {
  final String message;
  final bool isError;
  final int id;

  UiNotice(this.message, {this.isError = true}) : id = _next++;

  static int _next = 0;

  @override
  List<Object?> get props => [message, isError, id];
}
