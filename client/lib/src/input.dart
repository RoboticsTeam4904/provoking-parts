import 'dart:html';

abstract class InputField<T> {
  String name;
  Element elem;
  T get value;

  InputField(this.name, this.elem);

  void validateInput();
}

class DefaultInput extends InputField<String> {
  InputElement input;
  Function(DefaultInput) customInputValidation;

  @override
  String get value => input.value;

  DefaultInput(String type, String name,
      {String defaultValue, this.customInputValidation})
      : super(
            name,
            DivElement()
              ..children.addAll([
                SpanElement()..text = name,
                InputElement(type: type)
                  ..value = defaultValue
                  ..name = name
              ]));

  @override
  void validateInput() {
    if (value == null || value.isEmpty)
      throw FormatException("You must input something for $name.");
    customInputValidation(this);
  }
}

class EditMenu {
  DivElement elem;
  DivElement errors;
  List<InputField> fields;
  Function(Map<String, dynamic> json) onComplete;
  Function() onCancel;

  EditMenu(String title, this.fields, this.onComplete, {this.onCancel}) {
    onCancel ??= () {};
    elem = DivElement()
      ..className = "editMenu"
      ..children.addAll([
        SpanElement()
          ..className = "title"
          ..text = title,
        BRElement(),
        DivElement()
          ..className = "input"
          ..children.addAll(List.generate(fields.length, (i) {
            final field = fields[i];
            return DivElement()
              ..children.addAll([SpanElement()..text = field.name, field.elem]);
          })),
        errors = DivElement()..className = "errors",
        DivElement()
          ..className = "end"
          ..children.addAll([
            ButtonElement()
              ..className = "save"
              ..text = "Save"
              ..onClick.listen((_) {
                final json = assembleJson();
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
    final json = {};
    for (final field in fields) {
      try {
        field.validateInput();
      } on FormatException catch (e) {
        errors.children.add(DivElement()..text = e.toString());
      }
      json[field.name] = field.value;
    }
    return json;
  }
}
