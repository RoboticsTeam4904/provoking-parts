import 'dart:async';
import 'dart:html';
import 'package:client/client.dart';

Future<void> main() async {
  final session = Session(((_) {}), FetchClient());
  try {
    await session.init();
  } on StateError {
    // Redirect to authentication
    // window.location.pathname = "/google";
    return;
  } catch (e) {
    CustomAlert(Alert.error, "Init error: $e");
  }
  final modal = Modal(
      document.querySelector("#modal"), document.querySelector("#screenCover"));
  try {
    final dummyPart = PartHtml(
        PartModel(null, null, null, 0, null, session), modal, session,
        debug: true);
    document.querySelector("#newTopLevelPart").onClick.listen((_) {
      dummyPart.displayPartMenu(newPart: true);
    });
  } catch (e) {
    CustomAlert(Alert.error, "Dummy part error: $e");
  }
  final partsContainer = document.querySelector("#partsList");
  final htmlParts =
      session.parts.map((i, p) => MapEntry(i, PartHtml(p, modal, session)));
  for (final part in htmlParts.values) {
    if (part.model.parentID == null) partsContainer.children.add(part.elem);
  }
  final updateStream = session.pollForUpdates();
  session.onUpdate = (Map update) {
    if (update["new"] == null) if (update["model"] != "Status")
      session.removePart(session.parts[update["old"]["id"]]);
    else
      session.removeStatus(session.statuses[update["old"]["id"]]);
    else {
      if (update["model"] == "Part")
        session.updatePart(PartModel.fromJson(update["new"], session),
            updateParent: true);
      else
        session.updateStatus(StatusModel.fromJson(update["new"], session));
    }
    if (update["model"] == "Part") {
      if (update["new"] == null) {
        final oldID = update["old"]["id"];
        htmlParts.remove(oldID);
        partsContainer.querySelector("#part$oldID").remove();
      } else {
        if (update["old"] == null) {
          final newPart =
              PartHtml(session.parts[update["new"]["id"]], modal, session);
          htmlParts[newPart.model.id] = newPart;
          (newPart.model.parentID != null
                  ? htmlParts[newPart.model.parentID].childrenContainer
                  : partsContainer)
              .children
              .add(newPart.elem);
        } else {
          final newPart = htmlParts[update["new"]["id"]];
          newPart.elem.children.first = newPart.isolatedElem();
          if (update["old"]["parentID"] != update["new"]["parentID"]) {
            newPart.elem.remove();
            (newPart.model.parentID != null
                    ? htmlParts[newPart.model.parentID].childrenContainer
                    : partsContainer)
                .children
                .add(newPart.elem);
          }
        }
      }
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
  };
  try {
    await for (final update in updateStream) {

    }
  } catch (e) {
    print("big sad: $e");
    // CustomAlert(Alert.error, e.toString());
    // CustomAlert(Alert.warning, "Reloading page do to fatal error...");
    // await Future.delayed(Duration(seconds: 3))
    //     .then((_) => window.location.reload());
  } finally {
    // CustomAlert(Alert.error, "The server may have been destroyed?");
    // CustomAlert(Alert.warning, "Reloading page do to fatal error...");
    // await Future.delayed(Duration(seconds: 3))
    //     .then((_) => window.location.reload());
  }
}
