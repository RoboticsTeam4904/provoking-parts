import 'dart:async';
import 'dart:html';
import 'package:client/client.dart';

Future<void> main() async {
  final session = Session(FetchClient());
  try {
    await session.init();
  } on StateError {
    // Redirect to authentication
    window.location.pathname = "/google";
    return;
  } catch (e) {
    CustomAlert(Alert.error, "Init error: $e");
  }
  final modal = Modal(
      document.querySelector("#modal"), document.querySelector("#screenCover"));
  final dummyPart = PartHtml(
      PartModel(null, null, null, null, 0, null, session), modal, session,
      debug: true);
  document.querySelector("#newTopLevelPart").onClick.listen((_) {
    dummyPart.displayPartMenu(newPart: true);
  });
  final partsContainer = document.querySelector("#partsList");
  final htmlParts = Map.fromEntries(
          session.parts.entries.where((m) => m.value.parentID == null))
      .map((i, p) => MapEntry(i, PartHtml(p, modal, session)));
  for (final part in htmlParts.values) partsContainer.children.add(part.elem);
  htmlParts.addEntries(
      flatten(htmlParts.values).map((p) => MapEntry(p.model.id, p)));
  print(htmlParts);
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
            print("patching part");
            PartHtml newPart;
            if (update["old"] == null) {
              newPart = htmlParts[newPart.model.id] =
                  PartHtml(session.parts[update["new"]["id"]], modal, session);
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
              print(
                  "correct parent part? ${querySelector("#part$newPart.model.parentID") == parentPart.elem}");
              (parentPart?.childrenContainer ?? partsContainer)
                  .children
                  .add(newPart.elem);
              if (parentPart != null)
                parentPart.part.children.first =
                    parentPart.disclosureTriangle();
            }
          }
          print(session.parts.map((i, p) => MapEntry(i, p.toJson())));
        } else {
          if (update["new"] == null)
            CustomAlert(Alert.error, "pl0x don't do this to me rohan");
          else if (update["old"] != null) {
            final newStatus = StatusModel.fromJson(update["new"], session);
            document.querySelectorAll("#status${newStatus.id}").forEach(
                (status) => StatusHtml.updateStatusElement(status, newStatus));
          } else
            for (final part in htmlParts.values)
              part.status
                  .addOption(StatusHtml.fromID(update["new"]["id"], session));
        }
      }
    } catch (e) {
      CustomAlert(Alert.error, e.toString());
      CustomAlert(Alert.warning, "Reloading page deux to fatal error...");
      await Future.delayed(Duration(seconds: 3))
          .then((_) => window.location.reload());
    }
  }
}

List<PartHtml> flatten(List<PartHtml> parts) {
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
