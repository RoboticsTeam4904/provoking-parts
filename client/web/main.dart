import 'dart:async';
import 'dart:html';
import 'package:client/client.dart';

Future<void> main() async {
  Session session;
  try {
    session = await Session()
      ..init();
  } on StateError {
    // Redirect to authentication
    window.location.pathname = "/google";
    return;
  } catch (e) {
    CustomAlert(Alert.error, e.toString());
  }
  final modal = Modal(
      document.querySelector("#modal"), document.querySelector("#screenCover"));
  try {
    final dummyPart =
        PartHtml(PartModel("", null, null, 0, null, session), modal, session);
    document.querySelector("#newTopLevelPart").onClick.listen((_) {
      dummyPart.displayPartMenu(newPart: true, defaultJson: {"parentId": null});
    });
  } catch (e) {
    CustomAlert(Alert.error, e.toString());
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
          final oldId = update["old"]["id"];
          htmlParts.remove(oldId);
          partsContainer.querySelector("#part$oldId").remove();
        } else {
          if (update["old"] == null) {
            final newPart =
                PartHtml(session.parts[update["new"]["id"]], modal, session);
            htmlParts[newPart.model.id] = newPart;
            htmlParts[newPart.model.parentId]
                .childrenContainer
                .children
                .add(newPart.elem);
          } else {
            final newPart = htmlParts[update["new"]["id"]]..update();
            if (update["old"]["parentId"] != update["new"]["parentId"]) {
              newPart.elem.remove();
              htmlParts[newPart.model.parentId]
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
                .addOption(StatusHtml.fromId(update["new"]["id"], session));
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
