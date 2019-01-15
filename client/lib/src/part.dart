import 'dart:html';
import 'api.dart';
import 'custom_alert.dart';
import 'input.dart';
import 'modal.dart';
import 'status.dart';

const assetsPath = "/assets";
const disclosureTriangleImg = "$assetsPath/disctri";
const partImg = "$assetsPath/part.png";
const plusImg = "$assetsPath/plus.png";
const deleteImg = "$assetsPath/trashcan.png";
const loadingAnim = "$assetsPath/loading.png";

class PartHtml {
  Session session;
  DivElement elem;
  PartModel model;
  Modal modal;
  DivElement childrenContainer;
  StatusDropdown status;
  bool childrenDisplayed = false;
  bool debug;

  PartHtml(this.model, this.modal, this.session, {this.debug = false}) {
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
        ..children
            .addAll(model.children.map((m) => PartHtml(m, modal, session).elem))
    ]);

  DivElement isolatedElem() => DivElement()
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
        ..text = model.description,
      ImageElement(src: plusImg, width: 20, height: 20)
        ..className = "new"
        ..onClick.listen((e) {
          displayPartMenu(newPart: true);
          e.stopPropagation();
        }),
      ImageElement(src: deleteImg, width: 20, height: 20)
        ..className = "delete"
        ..onClick.listen((e) async {
          e.stopPropagation();
          if (!window.confirm(
              "Are you sure you would like to delete ${model.name} and all of its subparts?"))
            return;
          try {
            await session.update(model, UpdateType.delete);
          } catch (ex) {
            CustomAlert(Alert.error, ex.toString());
          }
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
          CustomAlert(Alert.warning,
              "Failed to update status of part ${model.name}. Reverting to previous Status.");
          CustomAlert(Alert.error, e.toString());
          status.selectID(oldID, callOnChange: false);
        }
      }))
          .elem
    ]);

  ImageElement disclosureTriangle() => model.children.isEmpty
      ? (ImageElement(src: partImg)..className = "icon")
      : (ImageElement(src: "${disclosureTriangleImg}true.png")
        ..onClick.listen((e) {
          childrenContainer.style.display =
              (childrenDisplayed = !childrenDisplayed) ? "none" : "";
          (e.target as ImageElement).srcset =
              "$disclosureTriangleImg${!childrenDisplayed}.png";
          e.stopPropagation();
        })
        ..className = "icon disclosureTri");

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
          defaultValue: newPart ? "" : model.description),
      StatusDropdown("statusID",
          session.statuses.values.map((s) => StatusHtml(s)).toList(),
          selectedStatus:
              newPart ? null : StatusHtml.fromID(status.value, session))
    ], (json) async {
      await session.update(PartModel.fromJson(json, session),
          newPart ? UpdateType.create : UpdateType.patch);
      modal.close();
    },
            defaultJson: newPart ? {"parentID": model.id} : model.toJson(),
            onCancel: modal.close)
        .elem);
  }
}
