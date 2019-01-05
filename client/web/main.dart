import 'dart:html';
import 'package:client/client.dart';

DivElement googleSignIn = document.querySelector("#googleSignIn");
DivElement partsList = document.querySelector("#partsList");

void main() async {
  await initOauthFlow();
  initAlertElem();
  initModalElems();
  googleSignIn.onClick.listen((_) async {
    try {
      await initSession();
    } catch (e) {
      customAlert(Alert.error, e.toString());
      return;
    }
    googleSignIn.remove();
    partsList.children = List<DivElement>.generate(session["partsList"].length,
        (i) => makeFullPart(session["partsList"][i], topLevel: true));
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
  });
}
