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
  bool childrenDisplayed = true;

  PartHtml(this.model, this.modal, this.session, {bool topLevel = false}) {
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

  DivElement isolatedElem() =>
    DivElement()
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
                    "$discloserTriangleImg$childrenDisplayed.png";
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
                newPart: true, defaultJson: {"parentId": model.parentId});
            e.stopPropagation();
          }),
        (status = StatusDropdown("status",
                session.statuses.values.map((s) => StatusHtml(s)).toList(),
                selectedStatus: StatusHtml.fromId(model.statusId, session)))
            .elem,
      ]);

  void displayPartMenu(
      {bool newPart = false, Map<String, dynamic> defaultJson}) {
    modal.show(EditMenu("Edit Part #${model.id}", [
      DefaultInput("text", "Name", defaultValue: newPart ? "" : model.name),
      DefaultInput("number", "Quantity",
          defaultValue: newPart ? "" : model.quantity.toString(),
          customInputValidation: (q) {
        final parsed = int.tryParse(q.value);
        if (parsed == null || parsed < 0)
          throw const FormatException("You must enter a natural number");
      }),
      StatusDropdown(
          "status", session.statuses.values.map((s) => StatusHtml(s)).toList(),
          selectedStatus:
              newPart ? null : StatusHtml.fromId(status.value, session))
    ], (json) {
      try {
        session.update(PartModel.fromJson(json, session), UpdateType.patch);
      } catch (e) {
        CustomAlert(Alert.error, e.toString());
      }
    }, defaultJson: defaultJson ?? {}, onCancel: modal.close)
        .elem);
  }

  void update() => elem.children.first = isolatedElem();
}
