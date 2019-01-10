import "dart:convert";

import 'package:client/client.dart';
import "package:http/testing.dart";
import "package:test/test.dart";

import 'utils.dart';

const sessionJson = {
  "parts": [
    {
      "id": 0,
      "name": "Top-level Assembly",
      "quantity": 1,
      "statusID": 1,
      "parentID": null
    },
    {"id": 1, "name": "Drivebase", "quantity": 1, "statusID": 1, "parentID": 0},
    {
      "id": 2,
      "name": "Drive Gearbox",
      "quantity": 4,
      "statusID": 0,
      "parentID": 1
    }
  ],
  "statuses": [
    {"id": 0, "label": "Complete", "color": 0x0fff0f},
    {"id": 1, "label": "Work in progress", "color": 0x0f0fff}
  ]
};

final updatesJson = [
  {
    "timestamp": DateTime.now().toUtc().toIso8601String(),
    "model": "Part",
    "old": {
      "id": 1,
      "name": "Drivebase",
      "quantity": 1,
      "statusID": 1,
      "parentID": 0
    },
    "new": {
      "id": 1,
      "name": "Drivebase",
      "quantity": 1,
      "statusID": 0,
      "parentID": 0
    }
  },
  {
    "timestamp": DateTime.now().toUtc().toIso8601String(),
    "model": "Status",
    "old": null,
    "new": {"id": 2, "label": "Ordered", "color": 0xffff0f}
  }
];

void main() {
  final client = MockClient((request) async {
    if (request.url.path == "api/init") {
      return respond(request, 200, body: jsonEncode(sessionJson));
    }

    if (request.url.path == "api/updates") {
      final body = StringBuffer()
        ..writeln()
        ..writeln(jsonEncode(updatesJson[0]))
        ..writeln()
        ..writeln()
        ..writeln(jsonEncode(updatesJson[1]))
        ..writeln();

      return respond(request, 200, body: body.toString());
    }

    return respond(request, 404);
  });

  final session = Session(client);

  test("correctly deserializes Part models", () {
    final parts = sessionJson["parts"];
    final serializedParts =
        parts.map((part) => PartModel.fromJson(part, session));

    expect(
        serializedParts,
        orderedEquals(parts.map((part) => PartModel(
            part["name"],
            part["statusID"],
            part["id"],
            part["quantity"],
            part["parentID"],
            session))));
  });

  test("correctly deserializes Status models", () {
    final statuses = sessionJson["statuses"];
    final serializedStatuses =
        statuses.map((status) => StatusModel.fromJson(status, session));

    expect(
        serializedStatuses,
        orderedEquals(statuses.map(
            (status) => StatusModel(status["label"], status["id"], session))));
  });

  test("initializes a session", () async {
    await session.initSession();

    expect(
        session.parts.entries,
        containsAll(sessionJson["parts"].map((part) =>
            MapEntry(part["id"], PartModel.fromJson(part, session)))));
    expect(
        session.statuses.entries,
        containsAll(sessionJson["statuses"].map((status) =>
            MapEntry(status["id"], StatusModel.fromJson(status, session)))));

    session.parts.values.forEach(
        (part) => expect(part, isIn(session.parts[part.parentId].children)));
  });

  test("correctly receives and applies updates", () async {
    await session.pollForUpdates().take(updatesJson.length).last;

    expect(session.parts.values,
        contains(PartModel.fromJson(updatesJson[0], session)));

    expect(session.statuses.values,
        contains(StatusModel.fromJson(updatesJson[1], session)));
  });
}
