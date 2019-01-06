import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

const endpoint = "http://parts.botprovoking.org:8080/api";
const clientID =
    "937917591629-f5du0ujs57bpu4f9vk4q1a2rm945v4tg.apps.googleusercontent.com";
enum Update { delete, put, patch }
enum Item { parts, statuses }

final client = Client();

Map<String, List<Map<String, dynamic>>> session = {
  "parts": [
    {
      "name": "rohan",
      "id": 0,
      "count": 1,
      "status": {
        "value": "will never be fixed",
        "color": "#000000",
        "id": 0,
      },
      "children": [
        {
          "name": "big dum",
          "id": 1,
          "parentID": 0,
          "count": 999999,
          "status": {
            "value": "no u",
            "color": "#ff0000",
            "id": 1,
          },
          "children": []
        }
      ]
    }
  ],
  "statuses": [
    {
      "value": "will never be fixed",
      "color": "#000000",
      "id": 0,
    },
    {
      "value": "no u",
      "color": "#ff0000",
      "id": 1,
    }
  ]
};
Map<String, Map<int, Map<String, dynamic>>> sortedSession = {};

Future<void> initSession() async {
  final resp = await client.get("$endpoint/init");
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    session = jsonDecode(resp.body);
    sortedSession
      ..["parts"] = mapify(session["parts"])
      ..["statuses"] = mapify(session["statuses"]);
    addChildrenSpecification(sortedSession["parts"]);
  } else {
    if (resp.statusCode == 401) throw StateError("Not authenticated");
    throw Exception("${resp.statusCode}: ${resp.body}");
  }
}

Future<String> update(
    Map<String, dynamic> json, Update updateType, Item itemType) async {
  Function method;
  switch (updateType) {
    case Update.delete:
      method = client.post;
      break;
    case Update.patch:
      method = client.patch;
      break;
    case Update.put:
      method = client.delete;
  }
  return await method(
          "$endpoint${itemType.toString().split(".").last}/${json["id"] ?? ""}",
          body: json)
      .body;
}

Stream<Map<String, dynamic>> pollForUpdates() async* {
  final StreamedResponse resp = await client.send(Request("POST", Uri.parse("$endpoint/updates")));
  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    yield {"err": await resp.stream.bytesToString()};
    await Future.delayed(Duration(seconds: 30));
  }
  String updateBuf = "";
  await for (String char in resp.stream.toStringStream()) {
    if (char != "\n") {
      updateBuf += char;
      continue;
    }
    if (updateBuf.isEmpty) continue;
    Map<String, dynamic> update;
    try {
      update = jsonDecode(updateBuf);
    } catch (_) {
      yield {"err": "Rohan is bad"};
    }
    updateBuf = "";
    final String itemKey = update["model"] != "part" ? "parts" : "statuses";
    if (update["new"] == null) {
      sortedSession[itemKey].remove(update["old"]["id"]);
      session[itemKey].remove(update["old"]);
    } else {
      addChildrenSpecification(update["new"]);
      sortedSession[itemKey][update["id"]] = update["new"];
      if (update["old"] == null) session[itemKey].add(update["new"]);
    }
    yield update;
  }
}

Map<int, Map<String, dynamic>> mapify(List<Map<String, dynamic>> json) =>
    Map.fromIterable(json, key: (e) => e["id"]);

void addChildrenSpecification(Map<int, Map<String, dynamic>> json) {
  for (var value in json.values)
    (json[value["parentID"]]["children"] ??= []).add(value);
}
