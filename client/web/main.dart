import 'dart:async';
import 'dart:html';
import 'package:client/client.dart';
import 'package:client/config.dart' as config;

Future<void> main() async {
  // Initialize alerts
  final alerts = AlertManager(querySelector('#alerts'));

  // Initialize the session
  final session = Session(FetchClient());
  try {
    await session.init();
  } on StateError {
    // Redirect to authentication
    window.location.pathname = config.API.authEndpoint;
    return;
  } catch (e) {
    // Authentication Failed
    alerts.show(
        CustomAlert(Alert.error, "Error while initializing the page: $e"));
    return;
  }

  // Initialize the modal
  final modal = Modal(querySelector("#modal"), querySelector("#screenCover"));

  // Initalize the html parts
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
  final htmlParts = <int, PartHtml>{}..[null] = dummyPart;
  htmlParts.addEntries(
      flatten(htmlParts.values).map((p) => MapEntry(p.model.id, p)));

  // Make orginization buttons
  querySelector("#sortNames").onClick.listen(
      (_) => dummyPart.sort((a, b) => a.model.name.compareTo(b.model.name)));
  querySelector("#sortStatuses").onClick.listen((_) => dummyPart.sort((a, b) {
        if (a.model.statusID == b.model.statusID)
          return a.model.name.compareTo(b.model.name);
        return a.model.statusID > b.model.statusID ? -1 : 1;
      }));
  bool allPartsDisplayed = false;
  querySelector("#cebi").onClick.listen((_) {
    void closeAllChildren(PartHtml part) => part
      .children.forEach((p) {
        if (p.children.isEmpty) return;
        if (allPartsDisplayed != p.childrenDisplayed) p.toggleChildrenDisplayed();
        closeAllChildren(p);
      });

    allPartsDisplayed = !allPartsDisplayed;
    closeAllChildren(dummyPart);
  });

  // Dark mode
  final keypressBuff = <int>[76, 69, 79, 73, 83, 67, 79, 79, 76, 35];
  bool darkModeEnabled = false;
  document.onKeyDown.listen((e) {
    keypressBuff
      ..removeAt(0)
      ..add(e.keyCode);
    for (int i = 0; i < keypressBuff.length; ++i)
      if (keypressBuff[i] != config.DarkMode.code[i]) return;
    final percent = (darkModeEnabled = !darkModeEnabled) ? config.DarkMode.percent : 0;
    querySelectorAll("html${config.DarkMode.whitelistedElements.join(",")}").style
      ..setProperty("-webkit-filter", "invert($percent%)")
      ..setProperty("-moz-filter", "invert($percent%)")
      ..setProperty("-o-filter:", "invert($percent%)")
      ..setProperty("-ms-filter", "invert($percent%)");
    document.body.style.backgroundColor =
        "#${(0xffffff * (1 - percent / 100) as int).toRadixString(16).padLeft(6, '0')}";
  });

  // Poll for updates
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
                  ?.addOption(StatusHtml.fromID(update["new"]["id"], session));
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
