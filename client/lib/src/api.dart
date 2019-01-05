import 'package:googleapis_auth/auth_browser.dart';
import 'dart:convert';
import 'dart:async';

const endpoint = "https://TODO.com/api/";
const clientID =
    "43209138071-pgsjmtnp3g4en3kdkn38jikruud4v55r.apps.googleusercontent.com";
enum Update { delete, create, patch }
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
  AuthClient authClient;
  Map<int, StatusModel> statuses = {};
  Map<int, PartModel> parts = {};

  Session();

  Future<String> initSession() async {
    authClient = await getOAuthClient();
    final resp = await authClient.get("$endpoint/init");
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, List<Map<String, dynamic>>> initJSON =
          jsonDecode(resp.body);
      for (Map<String, dynamic> statusJSON in initJSON["statuses"]) {
        final s = StatusModel.fromJson(statusJSON);
        statuses[s.id] = s;
      }
      for (Map<String, dynamic> partJSON in initJSON["parts"]) {
        final p = PartModel.fromJson(partJSON, statuses);
        parts[p.id] = p;
      }
      for (PartModel part in parts.values)
        parts[part.parentID].children?.add(part);
      return null;
    }
    return resp.body;
  }

  Future<AuthClient> getOAuthClient() => createImplicitBrowserFlow(
          ClientId(clientID, null), ["email", "name", "openid"])
      .then((flow) =>
          flow.clientViaUserConsent().then((client) => authClient = client));

  Future<String> update(
      Map<String, dynamic> json, Update updateType, ModelType type) async {
    Function method;
    Response resp;
    final url =
        "$endpoint${type.toString().split(".").last}/${json["id"] ?? ""}";
    switch (updateType) {
      case Update.delete:
        resp = await authClient.delete(url);
        break;
      case Update.patch:
        method = authClient.patch;
        break;
      case Update.create:
        method = authClient.post;
    }
    resp ??= await method(url, body: json).body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return null;
    return resp.body;
  }

  Stream<Map<String, dynamic>> pollForUpdates() async* {
    final StreamedResponse resp =
        await authClient.send(Request("POST", Uri.parse("$endpoint/updates")));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      yield {"err": await resp.stream.bytesToString()};
      return;
    }
    String updateBuf = "";
    await for (String char in resp.stream.toStringStream()) {
      if (char != "\n") {
        updateBuf += char;
        continue;
      }
      if (updateBuf.isEmpty) continue;
      Map<String, dynamic> update;
      update = jsonDecode(updateBuf);
      updateBuf = "";

      if (update["new"] == null) if (update["model"] != "status")
        parts.remove(update["old"]["id"]);
      else
        statuses.remove(update["old"]["id"]);
      else {
        if (update["model"] != "status") {
          final newPart = PartModel.fromJson(update["new"], statuses);
          parts[newPart.id] = newPart;
          parts[newPart.parentID].children.add(newPart);
        } else {
          final newStatus = StatusModel.fromJson(update["new"]);
          statuses[newStatus.id] = newStatus;
        }
      }
      yield update;
    }
  }
}

Map<int, Map<String, dynamic>> mapify(List<Map<String, dynamic>> json) =>
    Map.fromIterable(json, key: (e) => e["id"]);

void addChildrenSpecification(Map<int, Map<String, dynamic>> json) {
  for (var value in json.values)
    (json[value["parentID"]]["children"] ??= []).add(value);
}
