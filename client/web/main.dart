import 'dart:html';
import 'package:client/client.dart';

DivElement signIn = document.querySelector("#signIn");
DivElement partsList = document.querySelector("#partsList");

Future<void> main() async {
  initAlertElem();
  initModalElems();

  try {
    await initSession();
  } on StateError {
    // Redirect to authentication
    window.location.pathname = "/google";
  } catch (err) {
    customAlert(Alert.error, err.toString());
  }
  partsList.children = List<DivElement>.generate(session["parts"].length,
      (i) => makeFullPart(session["parts"][i], topLevel: true));
  await for (var update in pollForUpdates()) {
    if (update.containsKey("err")) {
      customAlert(Alert.error, update["err"]);
      return;
    }
    if (update["old"] == null)
      (partsList.querySelector("#${update["new"]["parentID"]}") ?? partsList)
          .children
          .add(
              makeFullPart(update["new"], topLevel: update["new"]["parentID"] == null));
    else if (update["new"] == null)
      partsList.querySelector("#${update["old"]["id"]}").remove();
    else
      partsList
          .querySelector("#${update["new"]["id"]}")
          .children
          .first = makeSinglePart(update["new"]);
  }
}
