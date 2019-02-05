import 'dart:html';
import 'package:client/config.dart' as config;

enum Alert { error, warning, success }

class AlertManager {
  Element alertsContainer;

  AlertManager(this.alertsContainer);

  void createAndShow(Alert type, String msg) => show(CustomAlert(type, msg));

  void show(CustomAlert alert) =>
      alertsContainer.children.insert(0, alert.elem);

  void close(CustomAlert alert) => alert.close();

  void closeAll() => alertsContainer.children.clear();
}

class CustomAlert {
  DivElement elem;

  CustomAlert(Alert type, String msg) {
    elem = DivElement()
      ..className = type.toString().replaceFirst(".", " ")
      ..text = msg
      ..children.add(ImageElement(src: config.Assets.closeWindow)
        ..className = "closeWindow"
        ..onClick.listen((_) => elem.remove()));
  }

  void close() => elem.remove();
}
