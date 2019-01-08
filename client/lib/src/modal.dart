import 'dart:html';

class Modal {
  Element modalContainer;
  Element msg;

  Modal(this.modalContainer, Element screenCover) {
    screenCover..onClick.listen((_) => close());
  }

  void show(Element msg) {
    modalContainer.children.add(msg..className += " modalMessage");
    modalContainer.style.display = "flex";
  }
  
  void close() { 
    modalContainer.style.display = "none";
    msg.remove();
  }
}
