import 'dart:io';

class FileManager {
  Future reset(String dir) async {
    String path = '$dir/imgs.txt';
    var file = File(path);
    print(file.existsSync());
  }
}
