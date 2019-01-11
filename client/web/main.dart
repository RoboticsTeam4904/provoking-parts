import 'dart:async';
import 'dart:html';
import 'package:client/client.dart';

Future<void> main() async {
  final session = Session();
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
  try {
    final dummyPart =
        PartHtml(PartModel(null, null, null, 0, null, session), modal, session, debug: true);
    document.querySelector("#newTopLevelPart").onClick.listen((_) {
      dummyPart.displayPartMenu(newPart: true, defaultJson: {"parentID": null});
    });
  } catch (e) {
    CustomAlert(Alert.error, "Dummy part error: $e");
  }
  final htmlParts =
      session.parts.map((i, p) => MapEntry(i, PartHtml(p, modal, session)));
  final partsContainer = document.querySelector("#partsList")
    ..children.addAll(htmlParts.values.map((p) => p.elem));
  final updateStream = session.pollForUpdates();
  try {
    await for (final update in updateStream) {
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
            htmlParts[newPart.model.parentID]
                .childrenContainer
                .children
                .add(newPart.elem);
          } else {
            final newPart = htmlParts[update["new"]["id"]]..update();
            if (update["old"]["parentID"] != update["new"]["parentID"]) {
              newPart.elem.remove();
              htmlParts[newPart.model.parentID]
                  .childrenContainer
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
    }
  } catch (e) {
    CustomAlert(Alert.error, e.toString());
    CustomAlert(Alert.warning, "Reloading page do to fatal error...");
    await Future.delayed(Duration(seconds: 3))
        .then((_) => window.location.reload());
  } finally {
    CustomAlert(Alert.error, "The server may have been destroyed?");
    CustomAlert(Alert.warning, "Reloading page do to fatal error...");
    await Future.delayed(Duration(seconds: 3))
        .then((_) => window.location.reload());
  }
}
