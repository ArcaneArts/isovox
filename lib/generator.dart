import 'dart:io';

import 'package:toxic/extensions/iterable.dart';

(int, int) topBrightnessContrast = (7, 5);
(int, int) leftBrightnessContrast = (-7, -3);
(int, int) rightBrightnessContrast = (0, 0);

String magickPath =
    "\"C:\\Program Files\\ImageMagick-7.1.1-Q16-HDRI\\magick.exe\"";
List<Future> _later = [];
Future<void> _executeCommand({
  required String output,
  String? top,
  String? left,
  String? right,
  String? side,
  String? all,
}) async {
  File f = File("${output}.bat");
  await f.writeAsString("""
@echo off
${magickPath} ^
( ${top ?? all} -brightness-contrast ${topBrightnessContrast.$1},${topBrightnessContrast.$2} -alpha set -virtual-pixel transparent ^
    +distort Affine "0,64 0,0   0,0 -87,-50  64,64 87,-50" ^
) ^
( ${left ?? side ?? all} -brightness-contrast ${leftBrightnessContrast.$1},${leftBrightnessContrast.$2} -alpha set -virtual-pixel transparent ^
    +distort Affine "64,0 0,0   0,0 -87,-50  64,64 0,100" ^
) ^
( ${right ?? side ?? all} -brightness-contrast ${rightBrightnessContrast.$1},${rightBrightnessContrast.$2} -alpha set -virtual-pixel transparent ^
    +distort Affine "0,0 0,0   0,64 0,100    64,0 87,-50" ^
) ^
-background none -compose plus -layers merge +repage ^
-bordercolor transparent -compose over ^
$output
$magickPath 
      """);

  await Process.run(f.absolute.path, [], runInShell: true);
  _later.add(f.delete());
}

void main() async {
  String s = Platform.pathSeparator;
  Directory input = Directory("assets${s}texture${s}block").absolute;
  Directory output = Directory("assets${s}texture${s}iso").absolute;

  print("Cleaning ${output.path}");

  if (output.existsSync()) {
    for (FileSystemEntity entity
        in output.listSync(recursive: true, followLinks: false)) {
      entity.deleteSync();
    }
  }

  output.createSync(recursive: true);

  print("Processing Textures in ${input.path}");

  List<String> names = [];

  for (File i in input.listSync().whereType<File>()) {
    names.add(i.path.split(s).last.split(".").first);
  }

  Map<String, ISOBlockGen> blocks = {};

  for (String i in names) {
    String n;
    ISOBlockGen b;
    if (i.endsWith("_top")) {
      n = i.substring(0, i.length - 4);
      b = blocks.putIfAbsent(n, () => ISOBlockGen())..top = i;
    } else if (i.endsWith("_left")) {
      n = i.substring(0, i.length - 5);
      b = blocks.putIfAbsent(n, () => ISOBlockGen())..left = i;
    } else if (i.endsWith("_right")) {
      n = i.substring(0, i.length - 6);
      b = blocks.putIfAbsent(n, () => ISOBlockGen())..right = i;
    } else if (i.endsWith("_side")) {
      n = i.substring(0, i.length - 5);
      b = blocks.putIfAbsent(n, () => ISOBlockGen())..side = i;
    } else {
      n = i;
      b = blocks.putIfAbsent(n, () => ISOBlockGen())..all = i;
    }
  }

  print("Found ${blocks.length} blocks");

  List<Future> futures = [];
  int q = 0;
  for (String name in blocks.keys) {
    print("- $name(${blocks[name]})");
    q++;
    futures.add(
        blocks[name]!.execute("${output.path}${s}$name.png", input).then((r) {
      q--;
      print("Wrote $name.png, $q remain");
    }));
  }
  await Future.wait(futures);

  for (String name in blocks.keys) {
    File f = File("${output.path}${s}$name.png");

    if (!f.existsSync()) {
      print("WARN: Can't find $name.png, retrying...");

      await blocks[name]!
          .execute("${output.path}${s}$name.png", input)
          .then((r) {
        q--;
        print("ReWrote $name.png, $q remain");
      });
    }
  }

  List<String> k = blocks.keys.toList();
  k.remove("air");
  k.insert(0, "air");

  File("${output.path}${s}palette.tsx").writeAsStringSync("""
<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.0" name="main" tilewidth="176" tileheight="202" tilecount="${blocks.length}" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
${k.mapIndexed((e, i) => """  <tile id="${i}"><image source="${e}.png" width="176" height="202"/></tile>""").join("\n")}
</tileset>
""");
  File("${output.path}${s}palette.json").writeAsStringSync("""{
${k.mapIndexed((e, i) => """ "${e}": ${i}""").join(",\n")}
}""");
  await Future.wait(_later);
}

class ISOBlockGen {
  String? top;
  String? left;
  String? right;
  String? side;
  String? all;

  @override
  String toString() => [
        all != null ? "a: $all" : "",
        top != null ? "t: $top" : "",
        left != null ? "l: $left" : "",
        right != null ? "r: $right" : "",
        side != null ? "s: $side" : ""
      ].where((i) => i.isNotEmpty).join(", ");

  Future<void> execute(String destination, Directory input) => _executeCommand(
        output: destination,
        top: top == null
            ? null
            : "${input.path}${Platform.pathSeparator}${top}.png",
        left: left == null
            ? null
            : "${input.path}${Platform.pathSeparator}${left}.png",
        right: right == null
            ? null
            : "${input.path}${Platform.pathSeparator}${right}.png",
        side: side == null
            ? null
            : "${input.path}${Platform.pathSeparator}${side}.png",
        all: all == null
            ? null
            : "${input.path}${Platform.pathSeparator}${all}.png",
      );
}
