import 'dart:html';
import 'api.dart';
import 'custom_alert.dart';
import 'input.dart';
import 'modal.dart';
import 'status.dart';

const discloserTriangleImg = "/disctri";
const partImg = "/part.png";
const plusImg = "/plus.png";
const loadingAnim = "/loading.png";

class PartHtml {
  Session session;
  DivElement elem;
  PartModel model;
  Modal modal;
  DivElement childrenContainer;
  StatusDropdown status;
  bool childrenDisplayed = false;
  bool debug;

  PartHtml(this.model, this.modal, this.session,
      {bool topLevel = false, this.debug = false}) {
    if (debug) return;
    fullElem(topLevel);
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
      model.children.isEmpty
          ? (ImageElement(src: partImg)..className = "icon")
          : (ImageElement(src: "${discloserTriangleImg}true.png")
            ..onClick.listen((e) {
              childrenContainer.style.display =
                  (childrenDisplayed = !childrenDisplayed) ? "none" : "";
              (e.target as ImageElement).srcset =
                  "$discloserTriangleImg${!childrenDisplayed}.png";
              e.stopPropagation();
            })
            ..className = "icon disclosureTri"),
      SpanElement()
        ..className = "name"
        ..text = model.name,
      SpanElement()
        ..className = "quantity"
        ..text = model.quantity.toString(),
      ImageElement(src: plusImg, width: 20, height: 20)
        ..className = "new"
        ..onClick.listen((e) {
          displayPartMenu(
              newPart: true, defaultJson: {"parentID": model.parentID});
          e.stopPropagation();
        }),
      (status = StatusDropdown("status",
              session.statuses.values.map((s) => StatusHtml(s)).toList(),
              selectedStatus: StatusHtml.fromID(model.statusID, session)))
          .elem,
    ]);

  void displayPartMenu(
      {bool newPart = false, Map<String, dynamic> defaultJson}) {
    modal.show(EditMenu("Edit Part #${model.id}", [
      DefaultInput("text", "name", "Name", defaultValue: newPart ? "" : model.name,),
      IntInput("quantity", "Quantity",
          defaultValue: newPart ? "" : model.quantity,
          customInputValidation: (q) {
        if (q.value < 0)
          throw const FormatException("You must enter a natural number");
      }),
      StatusDropdown(
          "statusID", session.statuses.values.map((s) => StatusHtml(s)).toList(),
          selectedStatus:
              newPart ? null : StatusHtml.fromID(status.value, session))
    ], (json) async {
      try {
        var p;
        try {
          p = PartModel.fromJson(json, session);
        } catch (e) {
          CustomAlert(Alert.error, "c $e");
        }
        await session.update(p,
            newPart ? UpdateType.create : UpdateType.patch);
        modal.close();
      } catch (e) {
        CustomAlert(Alert.error, "b $e");
      }
    }, defaultJson: defaultJson ?? {}, onCancel: modal.close)
        .elem);
  }

  void update() => elem.children.first = isolatedElem();
}
