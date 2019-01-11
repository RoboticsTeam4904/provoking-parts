import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:equatable/equatable.dart';

const endpoint = "http://parts.botprovoking.org/api";
const clientID =
    "43209138071-pgsjmtnp3g4en3kdkn38jikruud4v55r.apps.googleusercontent.com";
enum UpdateType { delete, create, patch }

abstract class Model extends Equatable {
  int get id;
  String get endpoint;

  Model(List props) : super(props);

  Map<String, dynamic> json();
}

class PartModel extends Model {
  @override
  int id;

  Session session;
  String name;
  List<PartModel> children = [];
  int quantity, parentId, statusId;
  StatusModel get status => session.statuses[statusId];

  @override
  String get endpoint => "parts";

  PartModel(this.name, this.statusId, this.id, this.quantity, this.parentId,
      this.session)
      : super([name, statusId, id, quantity, parentId, session]);

  factory PartModel.fromJson(Map<String, dynamic> json, Session session) =>
      PartModel(json["name"], json["statusID"], json["id"], json["quantity"],
          json["parentID"], session);

  @override
  Map<String, dynamic> json() => {
        "id": id,
        "name": name,
        "parentId": parentId,
        "quantity": quantity,
        "statusId": statusId
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
  Map<String, dynamic> json() => {
        "id": id,
        "label": label,
        "color": color
      };
}

class Session {
  final Client client;
  Map<int, StatusModel> statuses = {};
  Map<int, PartModel> parts = {};

  Session([Client client]) : client = client ?? Client();

  Future<void> init() async {
    final resp = await client.get("$endpoint/init");

    if (resp.statusCode == 401) {
      throw StateError("Not signed in");
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> initJson = jsonDecode(resp.body);
      for (Map<String, dynamic> statusJson in initJson["statuses"])
        updateStatus(StatusModel.fromJson(statusJson, this));
      for (Map<String, dynamic> partJson in initJson["parts"])
        updatePart(PartModel.fromJson(partJson, this));
      for (PartModel part in parts.values)
        parts[part.parentId]?.children?.add(part);
      
      return;
    }

    throw Exception("${resp.statusCode}: ${resp.body}");
  }

  Future<void> update(Model model, UpdateType updateType) async {
    final url = "$endpoint/${model.endpoint}/${model.id ?? ""}";
    Response resp;
    switch (updateType) {
      case UpdateType.delete:
        resp = await client.delete(url);
        break;
      case UpdateType.patch:
        resp = await client.patch(url, body: jsonEncode(model.json()));
        break;
      case UpdateType.create:
        resp = await client.post(url, body: jsonEncode(model.json()));
        break;
      default:
        throw UnimplementedError("Something really bad hapenned :(");
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    throw Exception("${resp.statusCode}: ${resp.body}");
  }

  Stream<Map<String, dynamic>> pollForUpdates() async* {
    final StreamedResponse resp =
        await client.send(Request("GET", Uri.parse("$endpoint/updates")));
    if (!(resp.statusCode >= 200 && resp.statusCode < 300)) {
      throw Exception(await resp.stream.bytesToString());
    }
    String updateBuf = "";
    await for (final msg in resp.stream.toStringStream())
      for (final char in msg.split('')) {
        if (char != "\n") {
          updateBuf += char;
          continue;
        } else if (updateBuf.isEmpty) continue;
        final update = jsonDecode(updateBuf);
        updateBuf = "";

        if (update["new"] == null) if (update["model"] == "Status")
          parts.remove(update["old"]["id"]);
        else
          statuses.remove(update["old"]["id"]);
        else {
          if (update["model"] == "Part")
            updatePart(PartModel.fromJson(update["new"], this));
          else
            updateStatus(StatusModel.fromJson(update["new"], this));
        }
        yield update;
      }
  }

  void updatePart(PartModel part) {
    parts[part.id] = part;
    parts[part.parentId]?.children?.add(part);
  }

  void updateStatus(StatusModel status) => statuses[status.id] = status;
}
