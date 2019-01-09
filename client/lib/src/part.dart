import 'dart:html';
import 'modal.dart';
import 'api.dart';
import 'status.dart';
import 'custom_alert.dart';

const discloserTriangleImg = "/disctri";
const partImg = "/part.png";
const plusImg = "/plus.png";
const loadingAnim = "/loading.png";

class PartHtml {
  DivElement elem;
  PartModel model;
  Modal modal;
  DivElement childrenContainer;
  StatusHtml status;
  bool childrenDisplayed = true;

  PartHtml(this.model, this.modal, {bool topLevel = false}) {
    elem = DivElement()
      ..className = "partContainer"
      ..id = "part${model.id}"
      ..style.paddingLeft = "${topLevel ? 0 : 20}px"
      ..children.addAll([
        isolatedPartElem(),
        childrenContainer = DivElement()
          ..className = "partChildren"
          ..children.addAll(List.generate(model.children.length,
              (i) => PartHtml(model.children[i], modal).elem))
      ]);
  }

  DivElement isolatedPartElem() => DivElement()
    ..className = "part"
    ..onClick.listen((_) => modal.show(partEditMenu(model)))
    ..children.addAll([
      model.children.isEmpty
          ? (ImageElement(src: partImg)..className = "icon")
          : (ImageElement(src: "${discloserTriangleImg}true.png")
            ..onClick.listen((e) {
              childrenContainer.style.display =
                (childrenDisplayed = !childrenDisplayed) ? "none" : "";
              (e.target as ImageElement).srcset = "${discloserTriangleImg}childrenDisplayed.png";
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
          modal.show(partEditMenu({"parentID": model.parentId}));
          e.stopPropagation();
        }),
      (status = StatusHtml.fromId(model.statusId)).elem,
    ]);
}
