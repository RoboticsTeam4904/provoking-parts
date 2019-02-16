import 'dart:async';
import 'dart:html';

abstract class InputField<T> {
  String name;
  Element elem;
  T get value;

  InputField(this.name, this.elem);

  void validateInput();
}

class DefaultInput extends InputField<String> {
  bool overrideDefaultValidation;
  InputElement input;
  Function(DefaultInput) customInputValidation;

  @override
  String get value => input.value;

  DefaultInput(String type, String name, String displayName,
      {String defaultValue = "",
      this.customInputValidation,
      this.overrideDefaultValidation = false})
      : super(
            name,
            DivElement()
              ..children.addAll([
                SpanElement()..text = displayName,
                InputElement(type: type)
                  ..value = defaultValue
                  ..name = name
              ])) {
    input = elem.querySelector("input");
  }

  @override
  void validateInput() {
    if (!overrideDefaultValidation && (value == null || value.isEmpty))
      throw FormatException("You must input something for $name.");
    if (customInputValidation != null) customInputValidation(this);
  }
}

class CheckboxInput extends InputField<bool> {
  InputElement input;

  @override
  bool get value => input.checked;

  CheckboxInput(String name, String displayName,
      {String defaultValue = ""})
      : super(
            name,
            DivElement()
              ..children.addAll([
                SpanElement()..text = displayName,
                InputElement(type: "checkbox")
                  ..value = defaultValue
                  ..name = name
              ])) {
    input = elem.querySelector("input");
  }

  @override
  void validateInput() {
    if (value == null)
      throw const FormatException("Something went horribly awry");
  }
}

class IntInput extends InputField<int> {
  InputElement input;
  Function(IntInput) customInputValidation;

  @override
  int get value => int.tryParse(input.value);

  IntInput(String name, String displayName,
      {var defaultValue, Function(IntInput) customInputValidation})
      : customInputValidation = customInputValidation ?? ((_) {}),
        super(
            name,
            DivElement()
              ..children.addAll([
                SpanElement()..text = displayName,
                InputElement(type: "number")
                  ..value = defaultValue.toString()
                  ..name = name
              ])) {
    input = elem.querySelector("input");
  }

  @override
  void validateInput() {
    if (value == null)
      throw FormatException("You must input something for $name.");
    customInputValidation(this);
  }
}

class SearchInput<T> extends InputField<T> {
  final Iterable<T> searchOptions;
  final Iterable<String> Function(Iterable<T> options, String query) search;
  final T Function(String query) getValueFromQuery;
  final int maxDisplayedSearchResults;
  InputElement searchBar;
  DivElement searchResultsContainer;

  @override
  T get value => getValueFromQuery(searchBar.value);

  SearchInput(String name, this.getValueFromQuery, this.searchOptions,
      this.search, this.maxDisplayedSearchResults)
      : super(name,
            DivElement()..children.addAll([InputElement(), DivElement()])) {
    searchBar = elem.querySelector("input")
      ..onChange.listen((_) {
        if (searchBar.value.trim() == "" || searchBar.value == null)
          searchResultsContainer.children.clear();
        else
          displayResults(search(searchOptions, searchBar.value));
      });
    searchResultsContainer = elem.querySelector("div");
  }

  void displayResults(List<String> results) {
    searchResultsContainer.children
      ..clear()
      ..addAll(List.generate(
          maxDisplayedSearchResults.clamp(0, results.length),
          (i) => DivElement()
            ..text = results[i]
            ..onClick.listen((_) {
              searchResultsContainer.children.clear();
              searchBar
                ..value = results[i]
                ..text = results[i];
            })));
  }

  @override
  void validateInput() {
    if (!searchOptions.contains(value))
      throw FormatException("\"${searchBar.value}\" not found as an option.");
    if (value == null) throw Exception("ABORT");
  }
}

class EditMenu {
  DivElement elem;
  DivElement errors;
  List<InputField> fields;
  Map<String, dynamic> defaultJson;
  Function(Map<String, dynamic> json) onComplete;
  Function() onCancel;

  EditMenu(String title, this.fields, this.onComplete,
      {Function() onCancel, Map<String, dynamic> defaultJson})
      : onCancel = onCancel ?? (() {}),
        defaultJson = defaultJson ?? {} {
    elem = DivElement()
      ..className = "editMenu"
      ..children.addAll([
        DivElement()
          ..className = "title"
          ..text = title,
        DivElement()
          ..className = "inputs"
          ..children.addAll(fields.map((f) => f.elem)),
        errors = DivElement()..className = "errors",
        DivElement()
          ..className = "end"
          ..children.addAll([
            ButtonElement()
              ..className = "save"
              ..text = "Save"
              ..onClick.listen((_) => save()),
            ButtonElement()
              ..className = "cancel"
              ..text = "Cancel"
              ..onClick.listen((_) => onCancel())
          ])
      ]);
  }

  Map<String, dynamic> assembleJson() {
    errors.children.clear();
    final json = Map<String, dynamic>.from(defaultJson);
    for (final field in fields) {
      try {
        field.validateInput();
      } on FormatException catch (e) {
        errors.children.add(DivElement()..text = e.message);
      }
      json[field.name] = field.value;
    }
    return json;
  }

  void save() {
    final json = assembleJson();
    if (errors.children.isNotEmpty) return;
    onComplete(json);
  }
}
