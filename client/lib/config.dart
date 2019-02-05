abstract class API {
  static const endpoint = "http://parts.botprovoking.org/api";
  static const authEndpoint = "/google";
}

abstract class Part {
  static const maxDescriptionLength = 100;
}

abstract class Assets {
  static const assetsPath = "assets";
  static const gear = "$assetsPath/part.png";
  static const plus = "$assetsPath/plus.png";
  static const delete = "$assetsPath/trashcan.png";
  static const loading = "$assetsPath/loading.png";
  static const closeWindow = "$assetsPath/closewindow.png";
  static const disclosureTriangle = {
    true: "$assetsPath/disctritrue.png",
    false: "$assetsPath/disctrifalse.png"
  };
}

abstract class DarkMode {
  static const code = <int>[38, 38, 40, 40, 37, 39, 37, 39, 66, 65];
  static const whitelistedElements = ["", "#alerts", ".color"];
  static const percent = 100;
}
