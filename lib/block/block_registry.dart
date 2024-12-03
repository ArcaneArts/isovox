import 'dart:convert';

import 'package:flame/flame.dart';
import 'package:isovox/block/block.dart';

class BlockRegistry {
  static late BlockRegistry instance;
  late Map<String, IsovoxBlock> blocksByName = {};
  late Map<int, IsovoxBlock> blocksById = {};
  late IsovoxBlock air;

  static Future<BlockRegistry> load() async {
    BlockRegistry b = BlockRegistry();
    instance = b;
    Map<String, dynamic> mapping = jsonDecode(
        await Flame.bundle.loadString("assets/texture/iso/palette.json"));

    for (String i in mapping.keys) {
      b.blocksByName[i] = IsovoxBlock(i, mapping[i]);
      b.blocksById[mapping[i]] = b.blocksByName[i]!;

      if (i == "air") {
        b.air = b.blocksByName[i]!;
      }
    }

    print("Loaded ${b.blocksByName.length} blocks");

    return b
      ..blocksById = Map.unmodifiable(b.blocksById)
      ..blocksByName = Map.unmodifiable(b.blocksByName);
  }
}
