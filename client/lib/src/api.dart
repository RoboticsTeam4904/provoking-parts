import 'dart:async';
import 'dart:convert';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

const endpoint = "https://botprovoking.org/api";
const clientID =
    "43209138071-pgsjmtnp3g4en3kdkn38jikruud4v55r.apps.googleusercontent.com";
enum UpdateType { delete, create, patch }
enum ModelType { part, status }

abstract class Model {}

class PartModel extends Model {
  String name;
  List<PartModel> children = [];
  Session session;
  int id, quantity, parentId, statusId;
  StatusModel get status => session.statuses[statusId];

  PartModel(this.name, this.statusId, this.id, this.quantity, this.parentId,
      this.session);

  PartModel.fromJson(Map<String, dynamic> json, Session session) {
    PartModel(json["name"], json["statusID"], json["id"], json["quantity"],
        json["parentID"], session);
  }
}

class StatusModel extends Model {
  String label;
  int id, color;

  StatusModel(this.label, this.id, this.color);

  StatusModel.fromJson(Map<String, dynamic> json) {
    StatusModel(json["label"], json["id"], json["color"]);
  }

  void updateFromJson() {

  }
}

class Session {
  final Client client;
  Map<int, StatusModel> statuses = {};
  Map<int, PartModel> parts = {};

  Session([Client client]) : client = client ?? BrowserClient();

  Future<void> initSession() async {
    final resp = await client.get("$endpoint/init");
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, List<Map<String, dynamic>>> initJson =
          jsonDecode(resp.body);
      for (Map<String, dynamic> statusJson in initJson["statuses"])
        addStatus(StatusModel.fromJson(statusJson));
      for (Map<String, dynamic> partJson in initJson["parts"])
        addPart(PartModel.fromJson(partJson, this));
      for (PartModel part in parts.values)
        parts[part.parentId].children?.add(part);
    }
    throw Exception("${resp.statusCode}: ${resp.body}");
  }

  Future<void> update(
      Map<String, dynamic> json, UpdateType updateType, ModelType type) async {
    Response resp;
    final url =
        "$endpoint/${type.toString().split(".").last}/${json["id"] ?? ""}";
    switch (updateType) {
      case UpdateType.delete:
        resp = await client.delete(url);
        break;
      case UpdateType.patch:
        resp = await client.patch(url, body: json);
        break;
      case UpdateType.create:
        resp = await client.post(url, body: json);
        break;
      default:
        throw UnimplementedError("Something really bad hapenned :(");
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    throw Exception("${resp.statusCode}: ${resp.body}");
  }

  Stream<Map<String, dynamic>> pollForUpdates() async* {
    final StreamedResponse resp =
        await client.send(Request("POST", Uri.parse("$endpoint/updates")));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      yield {"err": await resp.stream.bytesToString()};
      return;
    }
    String updateBuf = "";
    await for (String char in resp.stream.toStringStream()) {
      if (char != "\n") {
        updateBuf += char;
        continue;
      } else if (updateBuf.isEmpty) continue;
      final update = jsonDecode(updateBuf);
      updateBuf = "";

      if (update["new"] == null) if (update["model"] != "Status")
        parts.remove(update["old"]["id"]);
      else
        statuses.remove(update["old"]["id"]);
      else {
        if (update["model"] != "status") {
          final newPart = PartModel.fromJson(update["new"], this);
          parts[newPart.id] = newPart;
          parts[newPart.parentId].children.add(newPart);
        } else {
          final newStatus = statuses[update["new"]["statusId"]];
          statuses[newStatus.id] = newStatus;
        }
      }
      yield update;
    }
  }

  void addPart(PartModel part) => parts[part.id] = part;

  void addStatus(StatusModel status) => statuses[status.id] = status;
}
