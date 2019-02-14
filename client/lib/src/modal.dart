import 'dart:html';

class Modal {
  Element modalContainer;
  Element message;

  Modal(this.modalContainer, Element screenCover) {
    screenCover.onClick.listen((_) => close());
    document.onKeyPress.listen((press) {
      if (press.key == "Escape" || press.key == "Enter") close();
    });
  }

  void show(Element msg) {
    message = msg;
    modalContainer.children.add(message..className += " modalMessage");
    modalContainer.style.display = "flex";
  }

  void close() {
    modalContainer.style.display = "none";
    message?.remove();
  }
}
