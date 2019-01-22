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
  final dummyPart = PartHtml(
      PartModel(null, null, null, null, 0, null, session),
      session,
      modal,
      alerts,
      debug: true);
  querySelector("#newTopLevelPart").onClick.listen((_) {
    dummyPart.displayPartMenu(newPart: true);
  });
  final partsContainer = querySelector("#partsList");
  final htmlParts = Map.fromEntries(
          session.parts.entries.where((m) => m.value.parentID == null))
      .map((i, p) => MapEntry(i, PartHtml(p, session, modal, alerts)));
  for (final part in htmlParts.values) partsContainer.children.add(part.elem);
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
              final parentPart = htmlParts[newPart.model.parentID];
              (parentPart?.childrenContainer ?? partsContainer)
                  .children
                  .add(newPart.elem);
              if (parentPart != null)
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
