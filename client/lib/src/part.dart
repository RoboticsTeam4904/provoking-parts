import 'dart:html';
import 'package:client/config.dart' as config;
import 'api.dart';
import 'custom_alert.dart';
import 'input.dart';
import 'modal.dart';
import 'status.dart';

class PartHtml {
  Session session;
  DivElement elem, part, childrenContainer;
  ImageElement disclosureTriangleElem;
  List<PartHtml> children = [];
  PartModel model;
  Modal modal;
  AlertManager alerts;
  StatusDropdown status;
  bool childrenDisplayed = false;
  bool debug;

  PartHtml(this.model, this.session, this.modal, this.alerts,
      {this.debug = false}) {
    if (debug) return;
    fullElem(model.parentID == null);
  }

  DivElement fullElem(bool topLevel) => elem = DivElement()
    ..className = "partContainer"
    ..id = "part${model.id}"
    ..style.paddingLeft = "${topLevel ? 0 : 20}px"
    ..children.addAll([
      isolatedElem(),
      childrenContainer = DivElement()
        ..className = "partChildren"
        ..children.addAll(model.children.map((m) {
          final part = PartHtml(session.parts[m], session, modal, alerts);
          children.add(part);
          return part.elem;
        }))
    ]);

  DivElement isolatedElem() => part = DivElement()
    ..className = "part"
    ..onClick.listen((_) => displayPartMenu())
    ..children.addAll([
      disclosureTriangle(),
      SpanElement()
        ..className = "name"
        ..text = model.name,
      SpanElement()
        ..className = "quantity"
        ..text = "x${model.quantity}",
      SpanElement()
        ..className = "description"
        ..text = model.description == null
            ? ""
            : (model.description
                    .substring(
                        0,
                        config.Part.maxDescriptionLength
                            .clamp(0, model.description.length))
                    .trim() +
                (model.description.length > config.Part.maxDescriptionLength
                    ? "..."
                    : "")),
      ImageElement(src: config.Assets.plus, width: 20, height: 20)
        ..className = "new"
        ..onClick.listen((e) {
          e.stopPropagation();
          // this is done to close status dropdowns
          document.body.click();

          displayPartMenu(newPart: true);
        }),
      ImageElement(src: config.Assets.delete, width: 20, height: 20)
        ..className = "delete"
        ..onClick.listen((e) async {
          e.stopPropagation();
          // this is done to close status dropdowns
          document.body.click();

          if (!window.confirm(
              "Are you sure you would like to delete ${model.name} and all of its subparts?"))
            return;
          try {
            await session.update(model, UpdateType.delete);
          } catch (ex) {
            alerts.show(CustomAlert(Alert.error, ex.toString()));
          }
        }),
      ImageElement(src: config.Assets.copy, width: 20, height: 20)
        ..className = "copy"
        ..onClick.listen((e) {
          e.stopPropagation();
          // this is done to close status dropdowns
          document.body.click();

          modal.show(EditMenu("Move ${model.name}", [
            SearchInput(
                "destination",
                (query) => model.session.parts.values
                    .firstWhere((p) => p.name == query),
                model.session.parts.values,
                (_, query) => session
                    .searchPartsByString(query)
                    .take(config.Part.maxNumSearchResults)
                    .where((p) => p != model)
                    .map((p) => p.name),
                config.Part.maxNumSearchResults),
            CheckboxInput("copy", "Copy?"),
          ], (json) async {
            try {
              final PartModel newParent = json["destination"];
              if (json["copy"])
                await session.updateFromJson(
                    {"id": model.id, "parentId": newParent.id},
                    UpdateType.create,
                    config.API.partsEndpoint);
              else
                await session.updateFromJson(
                    {"id": model.id, "parentId": newParent.id},
                    UpdateType.patch,
                    config.API.partsEndpoint);
            } catch (e) {
              alerts
                ..show(CustomAlert(Alert.warning,
                    "Failed to ${json["copy"] ? "copy" : "move"} part ${model.name}."))
                ..show(CustomAlert(Alert.error, e.toString()));
            }
          }).elem);
        }),
      (status = StatusDropdown("status",
              session.statuses.values.map((s) => StatusHtml(s)).toList(),
              selectedStatus: StatusHtml.fromID(model.statusID, session),
              onChange: (oldID, newID) async {
        try {
          final Map<String, dynamic> json = model.toJson();
          json["statusID"] = status.selectedID;
          final updateModel = PartModel.fromJson(json, session);
          await session.update(updateModel, UpdateType.patch);
        } catch (e) {
          alerts
            ..show(CustomAlert(Alert.warning,
                "Failed to update status of part ${model.name}. Reverting to previous Status."))
            ..show(CustomAlert(Alert.error, e.toString()));
          status.selectID(oldID, callOnChange: false);
        }
      }))
          .elem
    ]);

  ImageElement disclosureTriangle() =>
      disclosureTriangleElem = model.children.isEmpty
          ? (ImageElement(src: config.Assets.gear)..className = "icon")
          : (ImageElement(src: config.Assets.disclosureTriangle[true])
            ..onClick.listen((e) {
              e.stopPropagation();
              // this is done to close status dropdowns
              document.body.click();

              toggleChildrenDisplayed();
            })
            ..className = "icon disclosureTri");

  void toggleChildrenDisplayed() {
    childrenContainer.style.display =
        (childrenDisplayed = !childrenDisplayed) ? "none" : "";
    disclosureTriangleElem.srcset =
        config.Assets.disclosureTriangle[!childrenDisplayed];
  }

  void displayPartMenu({bool newPart = false}) {
    modal.show(EditMenu(newPart ? "New part" : "Editing ${model.name}", [
      DefaultInput(
        "text",
        "name",
        "Name",
        defaultValue: newPart ? "" : model.name,
      ),
      IntInput("quantity", "Quantity",
          defaultValue: newPart ? "" : model.quantity,
          customInputValidation: (q) {
        if (q.value < 0)
          throw const FormatException("You must enter a natural number");
      }),
      DefaultInput("text", "description", "Description",
          defaultValue: newPart ? "" : model.description,
          overrideDefaultValidation: true),
      StatusDropdown("statusID",
          session.statuses.values.map((s) => StatusHtml(s)).toList(),
          selectedStatus:
              newPart ? null : StatusHtml.fromID(status.value, session))
    ], (json) async {
      try {
        await session.updateFromJson(
            json, newPart ? UpdateType.create : UpdateType.patch, "parts");
      } catch (e) {
        alerts.show(CustomAlert(Alert.error, e.toString()));
      }
      modal.close();
    },
            defaultJson: newPart ? {"parentID": model.id} : model.toJson(),
            onCancel: modal.close)
        .elem);
  }

  void sort(int Function(PartHtml a, PartHtml b) compare) {
    children.sort(compare);
    childrenContainer.children = children.map((p) => p.elem).toList();
    children.forEach((p) => p.sort(compare));
  }
}
