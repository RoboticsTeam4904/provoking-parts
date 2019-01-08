import 'dart:html';

enum Alert { error, warning, success }

const closeWindowImg = "/closewindow.png";

class CustomAlert {
  static DivElement alerts = document.querySelector("#alerts");
  DivElement elem;

  CustomAlert(Alert type, String msg) {
    alerts.children.insert(
        0,
        elem = DivElement()
          ..className = type.toString().replaceFirst(".", " ")
          ..text = msg
          ..children.add(ImageElement(src: closeWindowImg)
            ..className = "closeWindow"
            ..onClick.listen((_) => elem.remove())));
  }

  void close() => elem.remove();
}
