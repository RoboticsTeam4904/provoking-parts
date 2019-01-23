import 'dart:async';
import 'dart:html';
import 'package:client/client.dart';

Future<void> main() async {
  final alerts = AlertManager(querySelector('#alerts'));
  final session = Session(FetchClient());
  try {
    await session.init();
  } on StateError {
    // Redirect to authentication
    window.location.pathname = "/google";
    return;
  } catch (e) {
    alerts.show(CustomAlert(Alert.error, "Init error: $e"));
    return;
  }
  final modal = Modal(querySelector("#modal"), querySelector("#screenCover"));
  final partsContainer = querySelector("#partsList");
  final dummyPart = PartHtml(
      PartModel(null, null, null, null, 0, null, session),
      session,
      modal,
      alerts,
      debug: true)
    ..childrenContainer = partsContainer
    ..children = session.parts.values
        .where((p) => p.parentID == null)
        .map((p) => PartHtml(p, session, modal, alerts))
        .toList();
  dummyPart.childrenContainer.children
      .addAll(dummyPart.children.map((p) => p.elem));
  querySelector("#newTopLevelPart").onClick.listen((_) {
    dummyPart.displayPartMenu(newPart: true);
  });
  querySelector("#sortNames").onClick.listen(
      (_) => dummyPart.sort((a, b) => a.model.name.compareTo(b.model.name)));
  querySelector("#sortStatuses").onClick.listen((_) => dummyPart.sort((a, b) {
        if (a.model.statusID == null) return -1;
        if (a.model.statusID == b.model.statusID) return 1;
        return a.model.statusID > b.model.statusID ? -1 : 1;
      }));
  final htmlParts = <int, PartHtml>{}..[null] = dummyPart;
  htmlParts.addEntries(
      flatten(htmlParts.values).map((p) => MapEntry(p.model.id, p)));
  while (true) {
    try {
      final updateStream = session.pollForUpdates();
      await for (final update in updateStream) {
        print("update $update");
        if (update["model"] == "Part") {
          print("updating part");
          if (update["new"] == null) {
            final oldID = update["old"]["id"];
            print("deleting part $oldID");
            htmlParts[oldID].elem.remove();
            htmlParts.remove(oldID);
          } else {
            PartHtml newPart;
            if (update["old"] == null) {
              newPart = PartHtml(
                  session.parts[update["new"]["id"]], session, modal, alerts);
              htmlParts[newPart.model.id] = newPart;
            } else {
              newPart = htmlParts[update["new"]["id"]];
              newPart.part.replaceWith(newPart.isolatedElem());
              if (update["old"]["parentID"] != newPart.model.parentID)
                newPart.elem.remove();
            }
            print("new part ${newPart.model.toJson()}");
            if (update["old"] == null ||
                update["old"]["parentID"] != newPart.model.parentID) {
              print("(re) adding part to dom");
              final parentPart = htmlParts[newPart.model.parentID]
                ..childrenContainer.children.add(newPart.elem);
              if (parentPart.model.id != null)
                parentPart.part.children.first =
                    parentPart.disclosureTriangle();
            }
          }
        } else {
          if (update["new"] == null)
            alerts.show(
                CustomAlert(Alert.error, "pl0x don't do this to me rohan"));
          else if (update["old"] != null) {
            final newStatus = StatusModel.fromJson(update["new"], session);
            querySelectorAll("#status${newStatus.id}").forEach(
                (status) => StatusHtml.updateStatusElement(status, newStatus));
          } else
            for (final part in htmlParts.values)
              part.status
                  .addOption(StatusHtml.fromID(update["new"]["id"], session));
        }
      }
    } catch (e) {
      alerts
        ..show(CustomAlert(Alert.error, e.toString()))
        ..show(CustomAlert(
            Alert.warning, "Reloading page deux to fatal error..."));
      await Future.delayed(Duration(seconds: 3))
          .then((_) => window.location.reload());
    }
  }
}

List<PartHtml> flatten(Iterable<PartHtml> parts) {
  final result = <PartHtml>[];

  void recurse(PartHtml part) {
    if (part.children.isNotEmpty && part.model.parentID != null)
      result.add(part);
    for (final child in part.children) {
      result.add(child);
      recurse(child);
    }
  }

  parts.forEach(recurse);
  return result;
}
