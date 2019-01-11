import "dart:convert";

import "package:client/src/api.dart";
import "package:http/src/response.dart";
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
    {"id": 1, "label": "Work in progress", "color": 0x0f0fff},
    {"id": 2, "label": "Please help me", "color": 0xffffff}
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
    if (request.url.path == "/api/init") {
      return respond(request, 200, body: jsonEncode(sessionJson));
    }

    if (request.url.path == "/api/updates") {
      final body = StringBuffer()
        ..writeln()
        ..writeln(jsonEncode(updatesJson[0]))
        ..writeln()
        ..writeln()
        ..writeln(jsonEncode(updatesJson[1]))
        ..writeln();

      return respond(request, 200, body: body.toString());
    }

    const partsEndpoint = "/api/parts/";
    if (request.url.path.startsWith(partsEndpoint))
      return makeMockClientUpdateResponse(
          request,
          int.parse(request.url.path.substring(partsEndpoint.length)),
          ["id", "parentId", "name", "quantity", "statusId"]);

    const statusesEndpoint = "/api/statuses/";
    if (request.url.path.startsWith(statusesEndpoint))
      return makeMockClientUpdateResponse(
          request,
          int.parse(request.url.path.substring(statusesEndpoint.length)),
          ["id", "label", "color"]);

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
        orderedEquals(statuses.map((status) => StatusModel(
            status["label"], status["id"], status["color"], session))));
  });

  test("initializes a session", () async {
    await session.init();

    expect(
        session.parts.values.toList(),
        containsAll(sessionJson["parts"]
            .map((part) => PartModel.fromJson(part, session))
            .toList()));
    expect(
        session.statuses.values.toList(),
        containsAll(sessionJson["statuses"]
            .map((status) => StatusModel.fromJson(status, session))
            .toList()));

    session.parts.entries
        .forEach((entry) => expect(entry.key, equals(entry.value.id)));

    session.statuses.entries
        .forEach((entry) => expect(entry.key, equals(entry.value.id)));

    session.parts.values.where((p) => p.parentId != null).forEach(
        (part) => expect(part, isIn(session.parts[part.parentId].children)));
  });

  test("correctly receives and applies updates", () async {
    await session.pollForUpdates().take(updatesJson.length).last;

    expect(session.parts.values,
        contains(PartModel.fromJson(updatesJson[0]["new"], session)));

    expect(session.statuses.values,
        contains(StatusModel.fromJson(updatesJson[1]["new"], session)));
  });

  test("correctly formats and sends updates", () async {
    await session.update(PartModel.fromJson(sessionJson["parts"][0], session), UpdateType.delete);
    await session.update(PartModel.fromJson(sessionJson["parts"][1], session), UpdateType.create);
    await session.update(PartModel.fromJson(sessionJson["parts"][2], session), UpdateType.patch);

    await session.update(PartModel.fromJson(sessionJson["statuses"][0], session), UpdateType.delete);
    await session.update(PartModel.fromJson(sessionJson["statuses"][1], session), UpdateType.create);
    await session.update(PartModel.fromJson(sessionJson["statuses"][2], session), UpdateType.patch);
  });
}

Response makeMockClientUpdateResponse(
    request, id, List<String> requiredFields) {
  if (request.method.toLowerCase() == "delete") {
    if (!sessionJson.containsKey(id))
      return respond(request, 400,
          body: "Request to delete part that does not exist");
    if (request.body.isEmpty)
      return respond(request, 200);
    else
      return respond(request, 400,
          body: "Request to delete part $id had non-empty body");
  } else {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(request.body);
      if (json["id"] != id)
        return respond(request, 400,
            body: "Request json id did not correspond with endpoint");
    } on FormatException {
      return respond(request, 400,
          body: "Request body did not contain valid update json");
    }
    if (json.keys.where((s) => requiredFields.contains(s)).length ==
        json.keys.length)
      return respond(request, 400,
          body: "Request body did not contain all required fields");
    if (request.method.toLowerCase() == "post" && sessionJson.containsKey(id))
      return respond(request, 400,
          body: "Request to make part that already exists");
    if (request.method.toLowerCase() == "patch" && !sessionJson.containsKey(id))
      return respond(request, 400,
          body: "Request to change part that does not exist");
  }
  return respond(request, 200);
}
