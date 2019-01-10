import 'dart:convert';
import 'package:http/http.dart';

import '../../models/part.dart';
import '../../models/status.dart';
import '../reducers/models.dart';
import '../store.dart';

Epic<AppState> createUpdateEpic() {
  final client = Client();

  return (actions, store) async* {
    final response = await client.send(Request("POST", Uri.parse("/updates")));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // handle error
      await Future.delayed(Duration(seconds: 30));
    }

    final updateBuffer = StringBuffer();
    await for (final char in response.stream.toStringStream()) {
      if (char != "\n") {
        updateBuffer.write(char);
        continue;
      } else if (updateBuffer.isEmpty) continue;

      Map<String, dynamic> update;
      try {
        update = jsonDecode(updateBuffer.toString());
      } catch (_) {
        // handle error
      }
      
      updateBuffer.clear();

      switch (update["model"]) {
        case "Part":
          yield UpdateModelAction(
              previous: Part.fromJson(update["old"]),
              current: Part.fromJson(update["new"]));
          break;
        case "Status":
          yield UpdateModelAction(
              previous: Status.fromJson(update["old"]),
              current: Status.fromJson(update["new"]));
          break;
      }
    }
  };
}
