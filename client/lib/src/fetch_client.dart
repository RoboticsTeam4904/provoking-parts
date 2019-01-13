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
      ByteBuffer body,
      String credentials,
      String cache})
      : _options = {
          'method': method,
          'headers': headers,
          'body': body,
          'credentials': credentials,
          'cache': cache
        };

  dynamic toJS() => jsify(_options);
}

@JS('Response')
class FetchResponse {
  external int get status;
  external String get type;
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

@JS('window.fetch')
external dynamic _windowFetch(input, init);

Future<FetchResponse> _fetch(input, FetchInitOptions init) =>
    promiseToFuture(_windowFetch(input, init.toJS()));

Future<StreamReaderReadResult> _callRead(ReadableStreamDefaultReader reader) =>
    promiseToFuture(reader.read());

class FetchClient extends BaseClient {
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final body = await request.finalize().toBytes();
    print("${request.url}: $body");
    final response = await _fetch(
        request.url.toString(),
        FetchInitOptions(
            method: request.method,
            headers: request.headers,
            body: body.isEmpty ? null : body.buffer,
            credentials: 'same-origin',
            cache: 'no-store'));
    
    if (response.body == null) {
      throw UnsupportedError(
          'Firefox does not currently support the Fetch API by default. '
          'Please go to about:config and enable the javascript.options.streams '
          'flag.');
    }

    final responseStream = _readFromStreamReader(response.body.getReader());
    print("hola matey");
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
