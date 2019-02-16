abstract class API {
  static const endpoint = "http://parts.botprovoking.org/api";
  static const authEndpoint = "/google";
  static const initEndpoint = "init";
  static const partsEndpoint = "parts";
  static const statusesEndpoint = "statuses";
}

abstract class Part {
  static const maxDescriptionLength = 100;
  static const maxNumSearchResults = 5;
}

abstract class Assets {
  static const path = "assets";
  static const gear = "$path/part.png";
  static const plus = "$path/plus.png";
  static const delete = "$path/trashcan.png";
  static const copy = "$path/copy.png";
  static const loading = "$path/loading.gif";
  static const closeWindow = "$path/closewindow.png";
  static const disclosureTriangle = {
    true: "$path/disctritrue.png",
    false: "$path/disctrifalse.png"
  };
}

abstract class DarkMode {
  static const code = <int>[38, 38, 40, 40, 37, 39, 37, 39, 66, 65];
  static const whitelistedElements = ["", "#alerts", ".color"];
  static const percent = 100;
}
