import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class ChunkSynth {
  static Map<(int, int, int), String> _cache = {};

  static String synthChunk(int x, int y, int z) {
    (int, int, int) key = (x, y, z);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    ZLibEncoder e = ZLibEncoder();
    BytesBuilder bb = BytesBuilder();
    List<int> zr = [0, 0, 0, 0];
    for (int i = 0; i < x * z; i++) {
      bb.add(zr);
    }
    String layerData =
        base64Encode(e.encode(bb.takeBytes(), level: Deflate.BEST_COMPRESSION));
    String s = '''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.11.0" orientation="isometric" renderorder="right-down" width="$x" height="$z" tilewidth="176" tileheight="101" infinite="0" nextlayerid="${y + 1}" nextobjectid="1">
<editorsettings><chunksize width="$x" height="$z"/></editorsettings>
<tileset firstgid="1" source="../texture/iso/palette.tsx"/>
${List.generate(y, (i) => """<layer id="$i" name="$i" width="$x" height="$z"><data encoding="base64" compression="zlib">$layerData</data></layer>""").join("\n")}
</map>''';
    _cache[key] = s;
    return s;
  }
}
