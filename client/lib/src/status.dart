import 'dart:html';
import 'api.dart';

class StatusHtml {
  StatusModel model;
  SpanElement elem;
  DivElement colorElem;

  StatusHtml(this.model) {
    elem = SpanElement()
      ..className = "partStatus"
      ..id = "status${model.id}"
      ..text = "Status: ${model.label}"
      ..children.add(colorElem = DivElement()
        ..className = "statusColor"
        ..style.backgroundColor = "#${model.color.toRadixString(16))}";
  }

  void update() {
    elem.text = "Status: ${model.label}";
    colorElem.style.backgroundColor = "#${model.color.toRadixString(16))}";
  }
}

class StatusDropdown {
  DivElement elem;
  List<Element> options;
  DivElement optionsContainer;
  Element selected;
  DivElement selectedContainer;
  
  StatusDropdown(List<StatusHtml> statuses, {StatusModel selectedStatus}) {
    elem = DivElement()
      ..className = "statusDropdown"
      ..children.addAll([
        selectedContainer = DivElement()
          ..className = "selected",
        optionsContainer = DivElement()
          ..className = "options"
          ..children
            ..addAll(options = List.generate(statuses.length,
              (i) {
                final elem = statuses[i].elem.clone(true)
                return elem;
              }
            ))
      ])
    select(selectedStatus ?? SpanElement()..text = "Choose...");
  }

  void select(Element newSelected) {
    selected?.style.display = "";
    selectedContainer.children = [newSelected.clone(true)]
    selected = newSelected
      ..style.display = "none";
  }
}
