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
  StatusModel status;
  List<PartModel> children = [];
  int id, quantity, parentID;

  PartModel(this.name, this.status, this.id, this.quantity, this.parentID);

  PartModel.fromJson(
      Map<String, dynamic> json, Map<int, StatusModel> statuses) {
    PartModel(json["name"], statuses[json["statusID"]], json["id"],
        json["quantity"], json["parentID"]);
  }
}

class StatusModel extends Model {
  String label;
  int id, color;

  StatusModel(this.label, this.id, this.color);

  StatusModel.fromJson(Map<String, dynamic> json) {
    StatusModel(json["label"], json["id"], json["color"]);
  }
}

class Session {
  BrowserClient client = BrowserClient();
  Map<int, StatusModel> statuses = {};
  Map<int, PartModel> parts = {};

  Session();

  Future<void> initSession() async {
    final resp = await client.get("$endpoint/init");
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, List<Map<String, dynamic>>> initJson =
          jsonDecode(resp.body);
      for (Map<String, dynamic> statusJson in initJson["statuses"])
        addStatus(StatusModel.fromJson(statusJson));
      for (Map<String, dynamic> partJson in initJson["parts"])
        addPart(PartModel.fromJson(partJson, statuses));
      for (PartModel part in parts.values)
        parts[part.parentID].children?.add(part);
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
          final newPart = PartModel.fromJson(update["new"], statuses);
          parts[newPart.id] = newPart;
          parts[newPart.parentID].children.add(newPart);
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
