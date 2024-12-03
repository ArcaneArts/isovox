import 'package:isovox/block/block.dart';
import 'package:isovox/block/block_registry.dart';
import 'package:isovox/game/world/chunk.dart';
import 'package:loud/loud.dart';

abstract class ChunkGenerator {
  Future<void> generate(IChunk chunk);
}

class TypicalGenerator extends ChunkGenerator {
  late final IsovoxBlock grass;
  late final IsovoxBlock dirt;
  late final IsovoxBlock courseDirt;
  late final IsovoxBlock stone;
  late final IsovoxBlock deepSlate;
  late final NoisePlane noise;

  TypicalGenerator() {
    int height = 30;
    noise = SimplexProvider(seed: 1337)
        .scale(0.01)
        .fit(height * 0.162, (height * 0.95) - 1);
    grass = BlockRegistry.instance.blocksByName['grass']!;
    dirt = BlockRegistry.instance.blocksByName['dirt']!;
    courseDirt = BlockRegistry.instance.blocksByName['coarse_dirt']!;
    stone = BlockRegistry.instance.blocksByName['stone']!;
    deepSlate = BlockRegistry.instance.blocksByName['deepslate']!;
  }

  @override
  Future<void> generate(IChunk chunk) async {
    for (int i = 0; i < chunk.cw; i++) {
      for (int j = 0; j < chunk.cd; j++) {
        int height = noise
            .noise2((chunk.chunkX * chunk.cw) + i.toDouble(),
                (chunk.chunkZ * chunk.cd) + j.toDouble())
            .round();

        for (int k = height; k >= 0; k--) {
          int depth = height - k;

          if (depth == 0) {
            chunk.setBlock(i, k, j, grass);
          } else if (depth < 2) {
            chunk.setBlock(i, k, j, dirt);
          } else if (depth < 4) {
            chunk.setBlock(i, k, j, courseDirt);
          } else if (depth < 8) {
            chunk.setBlock(i, k, j, stone);
          } else {
            chunk.setBlock(i, k, j, deepSlate);
          }
        }
      }
    }
  }
}
