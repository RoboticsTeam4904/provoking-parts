import 'base.dart';

class Part extends Model {
  String name;
  int quantity;
  int statusID;
  int parentID;

  Part(int id, this.name, this.quantity, this.statusID, this.parentID)
      : super(id);
  
  Part.fromJson(Map<String, dynamic> json)
      : this(json["id"], json["name"], json["quantity"], json["statusID"],
            json["parentID"]);
}
