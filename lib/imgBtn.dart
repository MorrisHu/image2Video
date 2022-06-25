import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'file.dart';
import 'method.dart';

class ImgBtn extends StatefulWidget {
  const ImgBtn({Key? key}) : super(key: key);

  State<ImgBtn> createState() => _ImgBtnState();
}

class _ImgBtnState extends State<ImgBtn> {
  TextEditingController _controller = TextEditingController();
  TextEditingController _fpxController = TextEditingController();
  int num = 300;
  String flag = '0';
  List timeList = [];
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();

  @override
  void initState() async {
    super.initState();

    _requestPermission();
    _controller.text = '300';
    _controller.addListener(() {
      if (num == null) return;
      setState(() {
        num = int.parse(_controller.text);
      });
    });
    _fpxController.text = '10';
    String dir = (await getTemporaryDirectory()).path;
    FileManager().reset(dir);
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
  }

  Future<void> _press() async {
    setState(() {
      flag = '1';
    });
    MTimer mTimer = MTimer();
    String dir = (await getTemporaryDirectory()).path;
    // String appDir = (await getApplicationDocumentsDirectory()).path;
    // var bytesA = await rootBundle.load("lib/assets/a2.jpg");
    // var bytesB = await rootBundle.load("lib/assets/b2.jpg");
    // var bytesC = await rootBundle.load("lib/assets/c.jpg");
    // var bytesD = await rootBundle.load("lib/assets/d.jpg");
    // var bytesE = await rootBundle.load("lib/assets/e2.jpg");
    // List bts = [bytesA, bytesB, bytesC, bytesD, bytesE];
    mTimer.start('图片读取图片');
    List bts = [];
    for (var i = 1; i <= 52; i++) {
      bts.add(await rootBundle.load("lib/assets/fs$i.jpg"));
    }
    mTimer.start('图片写入&压缩');
    String fps = _fpxController.text == '' ? '10' : _fpxController.text;

    for (var i = 0; i < num; i++) {
      int k = i % 52;
      await writeToFile(bts[k], '$dir/fs$i.jpg');
      if (i == num - 1) {
        await FFmpegKit.execute(
            '-i $dir/fs$i.jpg -vf scale=-1:720 -q 75 $dir/$i.jpg');
      } else {
        FFmpegKit.execute(
            '-i $dir/fs$i.jpg -vf scale=-1:720 -q 75 $dir/$i.jpg');
      }
    }

    mTimer.start('开始合成');
    String videoPath = '$dir/output1.mp4';
    // print('$videoPath');
    try {
      FFmpegKit.execute('-r $fps -f image2 -i $dir/%d.jpg $videoPath')
          .then((session) async {
        mTimer.start('保存视频');
        final returnCode = await session.getReturnCode();
        print('session: $session');

        if (ReturnCode.isSuccess(returnCode)) {
          // SUCCESS
          print('SUCCESS');
          final result = await ImageGallerySaver.saveFile(videoPath);
          print(result);
        } else if (ReturnCode.isCancel(returnCode)) {
          // CANCEL
          print('CANCEL');
        } else {
          // ERROR
          print('ERROR');
        }
        var cache = mTimer.stop();
        print(cache.last);
        int length = await File(videoPath).length();
        cache.add({'label': '视频大小', 'time': '${length ~/ 1024}K'});
        int long = num ~/ int.parse(_fpxController.text);
        cache.add({'label': '视频长度', 'time': '${long}s'});
        setState(() {
          timeList = cache;
          flag = '2';
          CleanUtil.clear();
        });
      });
    } catch (e) {
      print(e);
    }
  }

  Future<File> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 180,
        margin: EdgeInsets.only(bottom: 20),
        child: TextField(
          focusNode: focusNode1,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "图片张数", hintText: "输入数字"),
          controller: _controller,
        ),
      ),
      Container(
        width: 180,
        margin: EdgeInsets.only(bottom: 20),
        child: TextField(
          focusNode: focusNode2,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "帧数", hintText: "输入数字"),
          controller: _fpxController,
        ),
      ),
      Container(
        margin: EdgeInsets.only(bottom: 20, left: 80, right: 80),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              child: Text("生成"),
              onPressed: () {
                focusNode1.unfocus();
                focusNode2.unfocus();
                _press();
              },
            ),
            ElevatedButton(
              child: Text("清缓存"),
              onPressed: () {
                focusNode1.unfocus();
                focusNode2.unfocus();
                CleanUtil.clear();
                setState(() {
                  flag = '0';
                });
              },
            ),
          ],
        ),
      ),
      Container(
        child: Builder(builder: (context) {
          return flag == '0'
              ? Text('无图')
              : flag == '1'
                  ? Text('处理中')
                  : Builder(builder: (context) {
                      List<Widget> times = [];
                      Widget gen(dynamic item, [double bottom = 0]) {
                        return Container(
                          margin: EdgeInsets.only(left: 100, bottom: bottom),
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                child: Text(item['label']),
                              ),
                              Text(item['time'])
                            ],
                          ),
                        );
                      }

                      debugPrint('$timeList');

                      for (var i = 0; i < timeList.length; i++) {
                        if (timeList.length - i == 3) {
                          times.add(gen(timeList[i], 10));
                        } else {
                          times.add(gen(timeList[i]));
                        }
                      }
                      return Column(
                        children: times,
                      );
                    });
        }),
      ),
    ]);
  }
}
