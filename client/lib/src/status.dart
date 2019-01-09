import 'dart:html';
import 'api.dart';
import 'input.dart';

class StatusHtml {
  SpanElement elem;
  StatusModel model;
  DivElement colorElem;

  StatusHtml(this.model) {
    elem = SpanElement()
      ..className = "status"
      ..id = "status${model.id}"
      ..text = "Status: ${model.label}"
      ..children.add(colorElem = DivElement()
        ..className = "color"
        ..style.backgroundColor = "#${model.color.toRadixString(16)}");
  }

  StatusHtml.fromId(int id, Session session) {
    StatusHtml(session.statuses[id]);
  }

  void update() {
    elem.text = "Status: ${model.label}";
    colorElem.style.backgroundColor = "#${model.color.toRadixString(16)}";
  }
}

class StatusDropdown {
  List<Element> options;
  DivElement optionsContainer;
  DivElement selectedContainer;
  Element selectedElement;
  int selectedId;

  StatusDropdown(List<StatusHtml> statuses, {StatusHtml selectedStatus}) {
    DivElement()
      ..className = "statusDropdown"
      ..children.addAll([
        selectedContainer = DivElement()..className = "selected",
        optionsContainer = DivElement()
          ..className = "options"
          ..children.addAll(options = List.generate(statuses.length, (i) {
            final status = statuses[i];
            final elem = statuses[i].elem.clone(true) as Element;
            elem.onClick.listen((_) => select(elem, status.model.id));
            return elem;
          }))
      ]);
    if (selectedStatus != null)
      select(selectedStatus.elem, selectedStatus.model.id);
    else
      selectedContainer.children = [SpanElement()..text = "Choose..."];
  }

  void select(Element newSelectedElement, int newSelectedId) {
    selectedId = newSelectedId;
    selectedElement?.style.display = "";
    selectedContainer.children = [newSelectedElement.clone(true)];
    selectedElement = newSelectedElement..style.display = "none";
  }
}
