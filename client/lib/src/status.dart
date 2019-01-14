import 'dart:async';
import 'dart:html';
import 'api.dart';
import 'input.dart';

class StatusHtml {
  DivElement elem;
  StatusModel model;
  DivElement colorElem;
  SpanElement labelElem;

  StatusHtml(this.model) {
    statusElem();
  }

  factory StatusHtml.fromID(int id, Session session) =>
      StatusHtml(session.statuses[id]);

  DivElement statusElem() => elem = DivElement()
    ..className = "status"
    ..id = "status${model.id}"
    ..children.addAll([
      labelElem = SpanElement()
        ..className = "label"
        ..text = model.label,
      colorElem = DivElement()
        ..className = "color"
        ..style.backgroundColor =
            "#${model.color.toRadixString(16).padLeft(6, '0')}"
    ]);

  static void updateStatusElement(Element elem, StatusModel model) {
    elem.children.addAll([
      SpanElement()
        ..className = "label"
        ..text = model.label,
      DivElement()
        ..className = "color"
        ..style.backgroundColor = "#${model.color.toRadixString(16)}"
    ]);
  }
}

class StatusDropdown extends InputField<int> {
  bool optionsDisplayed = false;
  DivElement optionsContainer;
  DivElement selectedContainer;
  Element selectedElement;
  void Function(int oldID, int newID) onChange;
  int selectedID;
  @override
  int get value => selectedID;

  factory StatusDropdown(String name, List<StatusHtml> statuses,
      {StatusHtml selectedStatus,
      void Function(int oldID, int newID) onChange}) {
    DivElement selectedContainer;
    DivElement optionsContainer;
    Element selectedElement;

    final elem = DivElement()
      ..className = "statusDropdown"
      ..children.addAll([
        selectedContainer = DivElement()..className = "selected",
        optionsContainer = DivElement()..className = "options"
      ]);
    return StatusDropdown._internal(name, elem, selectedStatus, statuses,
        onChange, optionsContainer, selectedContainer, selectedElement);
  }

  StatusDropdown._internal(
      String name,
      DivElement elem,
      StatusHtml selectedStatus,
      List<StatusHtml> statuses,
      this.onChange,
      this.optionsContainer,
      this.selectedContainer,
      this.selectedElement)
      : super(name, elem) {
    elem.onClick.listen((e) {
      optionsContainer.style.display =
          (optionsDisplayed = !optionsDisplayed) ? "" : "none";
      e.stopPropagation();
    });
    optionsContainer
      ..style.display = "none"
      ..children.addAll(List.generate(statuses.length, (i) {
        final status = statuses[i];
        final Element optionElem = statuses[i].elem.clone(true);
        if (status.model.id == selectedStatus?.model?.id)
          selectedElement = optionElem;
        optionElem.onClick.listen((_) => select(optionElem, status.model.id));
        return optionElem;
      }));
    if (selectedStatus != null)
      select(selectedElement, selectedStatus.model.id, callOnChange: false);
    else
      selectedContainer.children = [SpanElement()..text = "Choose a status..."];
  }

  void select(Element newSelectedElement, int newSelectedID,
      {bool callOnChange = true}) {
    final oldSelectedID = selectedID;
    selectedID = newSelectedID;
    selectedElement?.style?.display = "";
    selectedContainer.children = [newSelectedElement.clone(true)];
    selectedElement = newSelectedElement..style.display = "none";
    if (onChange != null && callOnChange) onChange(oldSelectedID, newSelectedID);
  }

  void selectID(int newSelectedID, {bool callOnChange = true}) {
    if (newSelectedID == null) return;
    select(
        optionsContainer.querySelector("#status$newSelectedID"), newSelectedID,
        callOnChange: callOnChange);
  }

  void addOption(StatusHtml newOption) {
    final Element elem = newOption.elem.clone(true);
    optionsContainer.children.add(elem);
    elem.onClick.listen((_) => select(elem, newOption.model.id));
  }

  @override
  void validateInput() {
    if (selectedID == null)
      throw const FormatException("You must select a valid status.");
  }
}
