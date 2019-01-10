import 'base.dart';

class Status extends Model {
  String label;
  int color;

  Status(int id, this.label, this.color) : super(id);

  Status.fromJson(Map<String, dynamic> json)
      : this(json["id"], json["label"], json["color"]);
}
