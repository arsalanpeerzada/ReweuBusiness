import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = ResponseBody Function(RequestOptions options);

/// Records requests and answers them from [handler], so tests can check the
/// exact request shape sent to the backend.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHandler handler;
  final List<RequestOptions> requests = [];

  FakeHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Wraps [data] in the backend's ApiResponse envelope.
Map<String, dynamic> envelope(Object? data) => {
      'status': 200,
      'message': 'Success',
      'path': '/test',
      'data': data,
    };
