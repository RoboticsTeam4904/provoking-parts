import 'dart:async';
import 'dart:html';
import 'custom_alert.dart';
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

  DefaultInput(String type, String name,
      {String defaultValue = "",
      Function(DefaultInput) customInputValidation,
      this.overrideDefaultValidation = false})
      : customInputValidation = customInputValidation ?? ((_) {}),
        super(
            name,
            DivElement()
              ..children.addAll([
                SpanElement()..text = name,
                InputElement(type: type)
                  ..value = defaultValue
                  ..name = name
              ])) {
    input = elem.lastChild;
  }

  @override
  void validateInput() {
    if (!overrideDefaultValidation && (value == null || value.isEmpty))
      throw FormatException("You must input something for $name.");
    customInputValidation(this);
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
              ..onClick.listen((_) {
                var json;
                try {
                  json = assembleJson();
                } catch (e) {
                  CustomAlert(Alert.error, e.toString());
                }
                print(errors);
                print(errors?.children);
                print(errors?.children?.isNotEmpty);
                if (errors.children.isNotEmpty) return;
                onComplete(json);
              }),
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
}
