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
      ..text = model.label
      ..children.add(colorElem = DivElement()
        ..className = "color"
        ..style.backgroundColor = "#${model.color.toRadixString(16)}");
  }

  StatusHtml.fromId(int id, Session session) {
    StatusHtml(session.statuses[id]);
  }

  void update() {
    elem.text = model.label;
    colorElem.style.backgroundColor = "#${model.color.toRadixString(16)}";
  }
}

class StatusDropdown extends InputField<int> {
  List<Element> options;
  DivElement optionsContainer;
  DivElement selectedContainer;
  Element selectedElement;
  int selectedId;
  @override
  int get value => selectedId;

  factory StatusDropdown(String name, List<StatusHtml> statuses,
      {StatusHtml selectedStatus}) {
    DivElement selectedContainer;
    DivElement optionsContainer;
    Element selectedElement;
    List<Element> options;

    final elem = DivElement()
      ..className = "statusDropdown"
      ..children.addAll([
        selectedContainer = DivElement()..className = "selected",
        optionsContainer = DivElement()..className = "options"
      ]);
    return StatusDropdown._internal(name, elem, selectedStatus, statuses,
        options, optionsContainer, selectedContainer, selectedElement);
  }

  StatusDropdown._internal(
      String name,
      DivElement elem,
      StatusHtml selectedStatus,
      List<StatusHtml> statuses,
      this.options,
      this.optionsContainer,
      this.selectedContainer,
      this.selectedElement)
      : super(name, elem) {
    selectedContainer.onClick.listen((_) =>
      optionsContainer.style.display = (optionsContainer.style.display == "none") ? "" : "none";
    );
    optionsContainer.children
        .addAll(options = List.generate(statuses.length, (i) {
      final status = statuses[i];
      final elem = statuses[i].elem.clone(true) as Element;
      if (status == selectedStatus) selectedElement = elem;
      elem.onClick.listen((_) => select(elem, status.model.id));
      return elem;
    }));
    if (selectedStatus != null)
      select(selectedElement, selectedStatus.model.id);
    else
      selectedContainer.children = [SpanElement()..text = "Choose..."];
  }

  void select(Element newSelectedElement, int newSelectedId) {
    selectedId = newSelectedId;
    selectedElement?.style?.display = "";
    selectedContainer.children = [newSelectedElement.clone(true)];
    selectedElement = newSelectedElement..style.display = "none";
  }

  @override
  void validateInput() {
    if (selectedId == null)
      throw const FormatException("You must selected a valid status.");
  }
}
