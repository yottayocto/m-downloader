import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  var conf = jsonDecode(await new File('config.json').readAsString());
  var max_id = 1e18.ceil();
  var output = [];
  while (true) {
    var url = Uri.https(conf["authority"], "/api/v1/timelines/public",
        {"local": "true", "max_id": "${max_id}", "limit": "100"});
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse.length == 0) break;
      max_id = int.parse(jsonResponse.last["id"]);
      jsonResponse
          .removeWhere((item) => item["account"]["id"] != conf["account_id"]);
      output += jsonResponse;
      jsonResponse.forEach((toot) {
        max_id = min(int.parse(toot["id"]), max_id);
        if (toot["card"] is Map &&
            toot["card"]["image"] is String &&
            toot["card"]["image"].length > 0) {
          http.get(Uri.parse(toot["card"]["image"])).then((image) {
            if (image.statusCode == 200) {
              new File('./images/' +
                      sha256
                          .convert(utf8.encode(toot["card"]["image"]))
                          .toString())
                  .writeAsBytes(image.bodyBytes);
            } else {
              print("images: Request failed with status: ${image.statusCode}.");
              return;
            }
          });
        }
      });
    } else {
      print("toots: Request failed with status: ${response.statusCode}.");
      return;
    }
  }
  new File('./output.json').writeAsString(jsonEncode(output));
}