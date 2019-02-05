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
      "name": "IF YOU CAN SEE THIS DON'T WORRY, JUST NOTIFY LEO",
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
        int.tryParse(request.url.path.substring(partsEndpoint.length)),
        Set.from(["id", "parentID", "name", "quantity", "statusID"]),
        sessionJson["parts"]);

  const statusesEndpoint = "/api/statuses/";
  if (request.url.path.startsWith(statusesEndpoint))
    return makeMockClientUpdateResponse(
        request,
        int.tryParse(request.url.path.substring(statusesEndpoint.length)),
        Set.from(["id", "label", "color"]),
        sessionJson["statuses"]);

  return respond(request, 404);
});

void main() {
  final session = Session(client);

  test("correctly deserializes Part models", () {
    final parts = sessionJson["parts"];
    final serializedParts =
        parts.map((part) => PartModel.fromJson(part, session));

    expect(
        serializedParts,
        orderedEquals(parts.map((part) => PartModel(
            part["name"],
            part["description"],
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

    session.parts.values.where((p) => p.parentID != null).forEach(
        (part) => expect(part, isIn(session.parts[part.parentID].children)));
  });

  test("correctly receives and applies updates", () async {
    await session.pollForUpdates().take(updatesJson.length).last;

    expect(session.parts.values,
        contains(PartModel.fromJson(updatesJson[0]["new"], session)));

    expect(session.statuses.values,
        contains(StatusModel.fromJson(updatesJson[1]["new"], session)));
  });

  // test("correctly formats and sends updates", () async {
  //   await session.update(PartModel.fromJson(sessionJson["parts"][0], session),
  //       UpdateType.delete);
  //   await session.update(
  //       PartModel.fromJson(sessionJson["parts"][1], session), UpdateType.patch);
  //   await session.update(
  //       PartModel("test", 0, null, 1, null, session), UpdateType.create);

  //   await session.update(
  //       StatusModel.fromJson(sessionJson["statuses"][0], session),
  //       UpdateType.delete);
  //   await session.update(
  //       StatusModel.fromJson(sessionJson["statuses"][1], session),
  //       UpdateType.patch);
  //   await session.update(
  //       StatusModel("test", null, 0xffffff, session), UpdateType.create);
  // });
}

Response makeMockClientUpdateResponse(request, int id,
    Set<String> requiredFields, List<Map<String, dynamic>> sessionModelJson) {
  if (request.method.toLowerCase() == "delete") {
    if (sessionModelJson.firstWhere((m) => m["id"] == id).isEmpty)
      return respond(request, 400,
          body: "$id: Request to delete model that does not exist");
    if (request.body.isEmpty)
      return respond(request, 200);
    else
      return respond(request, 400,
          body: "$id: Request to delete model had non-empty body");
  } else {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(request.body);
    } on FormatException {
      return respond(request, 400,
          body: "$id: Request body did not contain valid update json");
    }
    if (request.method.toLowerCase() == "post" && json["id"] != null)
      return respond(request, 400,
          body: "Requests to make parts must have no id");
    if (request.method.toLowerCase() == "patch") {
      final requestFields = Set.from(json.keys);
      if (!requestFields.containsAll(requiredFields))
        return respond(request, 400,
            body:
                "$id: Request body did not contain the following required fields: ${requestFields.difference(requiredFields)}, $json");

      if (json["id"] != id)
        return respond(request, 400,
            body: "$id: Requests id must corrospond with endpoint id");
      if (sessionModelJson.where((m) => m["id"] == id).isEmpty)
        return respond(request, 400,
            body: "$id: Request to change part that does not exist");
    }
  }
  return respond(request, 200);
}
