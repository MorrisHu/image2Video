import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MTimer {
  List timeList = [];
  void start([String label = '']) {
    if (label != '') print(label);
    Map item = {'label': label, 'time': new DateTime.now()};
    timeList.add(item);
  }

  List stop() {
    start();
    List strList = [];
    for (var i = 0; i < timeList.length - 1; i++) {
      Map item = {
        'label': timeList[i]['label'],
        'time': (timeList[i + 1]['time']
                    .difference(timeList[i]['time'])
                    .inMilliseconds)
                .toString() +
            'ms'
      };
      strList.add(item);
    }
    Map last = {
      'label': '总时长',
      'time': (timeList.last['time']
                  .difference(timeList.first['time'])
                  .inMilliseconds)
              .toString() +
          'ms'
    };
    strList.add(last);
    timeList.clear();
    return strList;
  }
}

class CleanUtil {
  static Future<void> clear() async {
    Directory tempDir = (await getTemporaryDirectory());
    if (tempDir == null) return;
    await _delete(tempDir);
  }

  static Future<void> _delete(FileSystemEntity file) async {
    if (file is Directory) {
      final List<FileSystemEntity> children = file.listSync();
      for (final FileSystemEntity child in children) {
        await _delete(child);
      }
    } else {
      await file.delete();
    }
  }
}
