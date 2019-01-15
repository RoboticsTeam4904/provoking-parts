import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:equatable/equatable.dart';
import 'package:http/browser_client.dart';

var a = BrowserClient();

const endpoint = "http://parts.botprovoking.org/api";
const clientID =
    "43209138071-pgsjmtnp3g4en3kdkn38jikruud4v55r.apps.googleusercontent.com";
enum UpdateType { delete, create, patch }

abstract class Model extends Equatable {
  int get id;
  String get endpoint;

  Model(List props) : super(props);

  Map<String, dynamic> toJson();

  void updateFromJson(Map<String, dynamic> updateJson);
}

class PartModel extends Model {
  @override
  int id;

  Session session;
  String name;
  String description;
  List<PartModel> children = [];
  int quantity, parentID, statusID;
  StatusModel get status => session.statuses[statusID];

  @override
  String get endpoint => "parts";

  PartModel(this.name, this.description, this.statusID, this.id, this.quantity, this.parentID,
      this.session)
      : super([name, statusID, id, quantity, parentID, session]);

  factory PartModel.fromJson(Map<String, dynamic> json, Session session) =>
      PartModel(json["name"], json["description"], json["statusID"], json["id"], json["quantity"],
          json["parentID"], session);

  @override
  void updateFromJson(Map<String, dynamic> updateJson) {
    if (updateJson["name"] != null) name = updateJson["name"];
    if (updateJson["description"] != null) name = updateJson["name"];
    if (updateJson["statusID"] != null) statusID = updateJson["statusID"];
    if (updateJson["quantity"] != null) quantity = updateJson["quantity"];
    if (updateJson["parentID"] != null) parentID = updateJson["parentID"];
  }

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "parentID": parentID,
        "name": name,
        "description": description,
        "quantity": quantity,
        "statusID": statusID
      };
}

class StatusModel extends Model {
  @override
  int id;
  Session session;
  String label;
  int color;

  @override
  String get endpoint => "statuses";

  StatusModel(this.label, this.id, this.color, this.session)
      : super([label, id, color, session]);

  factory StatusModel.fromJson(Map<String, dynamic> json, session) =>
      StatusModel(json["label"], json["id"], json["color"], session);

  @override
  Map<String, dynamic> toJson() => {"label": label, "color": color, "id": id};

  @override
  void updateFromJson(Map<String, dynamic> updateJson) {
    if (updateJson["label"] != null) label = updateJson["label"];
    if (updateJson["color"] != null) color = updateJson["color"];
  }
}

class Session {
  final Client client;
  Map<int, StatusModel> statuses = {};
  Map<int, PartModel> parts = {};

  Session(this.client);

  Future<void> init() async {
    final resp = await client.get("$endpoint/init");

    if (resp.statusCode == 401) {
      throw StateError("Not signed in");
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> initJson = jsonDecode(resp.body);
      for (final statusJson in initJson["statuses"])
        updateStatus(StatusModel.fromJson(statusJson, this));
      for (final partJson in initJson["parts"])
        updatePart(PartModel.fromJson(partJson, this));
      parts = Map.fromEntries(parts.entries.toList()
        ..sort((part1, part2) => part1.value.name.compareTo(part2.value.name)));
      for (final part in parts.values)
        parts[part.parentID]?.children?.add(part);
      parts.removeWhere((_, p) =>
          (!parts.containsKey(p.parentID) && p.parentID != null) ||
          !statuses.containsKey(p.statusID)); //TODO
      return;
    }

    throw Exception("${resp.statusCode}: ${resp.body}");
  }

  Future<void> update(Model model, UpdateType updateType) async {
    final url = "$endpoint/${model.endpoint}/${model.id ?? ""}";
    Response resp;
    print(model.toJson());
    switch (updateType) {
      case UpdateType.delete:
        resp = await client.delete(url);
        break;
      case UpdateType.patch:
        resp = await client.patch(url,
            body: jsonEncode(model.toJson()),
            headers: {"content-type": "application/json"});
        break;
      case UpdateType.create:
        resp = await client.post(url,
            body: jsonEncode(model.toJson()),
            headers: {"content-type": "application/json"});
        break;
      default:
        throw UnimplementedError("Something really bad hapenned :(");
    }
    if (!(resp.statusCode >= 200 && resp.statusCode < 300))
      throw Exception(
          "Failed to $updateType at $url: ${resp.statusCode}: ${resp.body}");
  }

  Stream<Map<String, dynamic>> pollForUpdates() async* {
    final resp =
        await client.send(Request("GET", Uri.parse("$endpoint/updates")));
    if (!(resp.statusCode >= 200 && resp.statusCode < 300)) {
      throw Exception(await resp.stream.bytesToString());
    }
    String updateBuf = "";
    await for (final msg in resp.stream.toStringStream())
      for (final char in msg.split('')) {
        print("char$char");
        if (char != "\n") {
          updateBuf += char;
          continue;
        } else if (updateBuf.isEmpty) continue;
        final update = jsonDecode(updateBuf);
        updateBuf = "";

        if (update["new"] == null) if (update["model"] != "Status")
          removePart(parts[update["old"]["id"]]);
        else
          removeStatus(statuses[update["old"]["id"]]);
        else {
          if (update["model"] == "Part")
            updatePart(PartModel.fromJson(update["new"], this),
                updateParent: true);
          else
            updateStatus(StatusModel.fromJson(update["new"], this));
        }
        yield update;
      }
  }

  void updatePart(PartModel part, {bool updateParent = false}) {
    if (parts.containsKey(part.id))
      parts[part.id].updateFromJson(part.toJson());
    else
      parts[part.id] = part;
    if (updateParent) parts[part.parentID]?.children?.add(part);
  }

  void removePart(PartModel part) {
    parts.remove(part.id);
    parts[part.parentID]?.children?.remove(part);
  }

  void updateStatus(StatusModel status) {
    if (statuses.containsKey(status.id))
      statuses[status.id].updateFromJson(status.toJson());
    else
      statuses[status.id] = status;
  }

  void removeStatus(StatusModel status) => statuses.remove(status.id);
}
