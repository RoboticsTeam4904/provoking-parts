import "package:http/http.dart";

Response respond(Request request, int statusCode,
    {String body = "", Map<String, String> headers = const {}}) {
  final responseHeaders = {"content-type": "application/json"}..addAll(headers);
  return Response(body, statusCode, request: request, headers: responseHeaders);
}
