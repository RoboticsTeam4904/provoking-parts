// This code is super bad and hacky.
@JS()
library client.fetch_client;

import 'dart:html';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

class FetchInitOptions {
  final Map _options;

  FetchInitOptions(
      {String method,
      Map<String, String> headers,
      Uint8List body,
      String credentials,
      String cache})
      : _options = {
          'method': method,
          'headers': jsify(headers),
          'body': body,
          'credentials': credentials,
          'cache': cache
        };

  Map toMap() => _options;
}

@JS('Response')
class FetchResponse {
  external int get status;
  external ReadableStream get body;
}

@JS('ReadableStream')
class ReadableStream {
  external ReadableStreamDefaultReader getReader();
}

@JS('ReadableStreamDefaultReader')
class ReadableStreamDefaultReader {
  external dynamic read();
}

@anonymous
@JS()
class StreamReaderReadResult {
  external Uint8List get value;
  external bool get done;
}

Future<FetchResponse> _fetch(input, FetchInitOptions init) =>
    window.fetch(input, init.toMap());

Future<StreamReaderReadResult> _callRead(ReadableStreamDefaultReader reader) =>
    promiseToFuture(reader.read());

class FetchClient extends BaseClient {
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final body = await request.finalize().toBytes();

    final response = await _fetch(
        null,
        FetchInitOptions(
            method: request.method,
            headers: jsify(request.headers),
            body: body,
            credentials: 'same-origin',
            cache: 'no-store'));

    final responseStream = _readFromStreamReader(response.body.getReader());
    return StreamedResponse(responseStream, response.status, request: request);
  }

  Stream<Uint8List> _readFromStreamReader(
      ReadableStreamDefaultReader reader) async* {
    while (true) {
      final state = await _callRead(reader);
      if (state.value != null) yield state.value;
      if (state.done) {
        break;
      }
    }
  }
}
