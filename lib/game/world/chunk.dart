import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame_tiled_utils/flame_tiled_utils.dart';
import 'package:isovox/block/block.dart';
import 'package:isovox/block/block_registry.dart';
import 'package:isovox/game/game.dart';
import 'package:isovox/util/chunk_synth.dart';

class IChunk extends PositionComponent {
  static ImageBatchCompiler imageCompiler = ImageBatchCompiler();
  final int chunkX;
  final int chunkY;
  final int chunkZ;
  late TiledComponent chunkMap;
  late List<bool> dirtyLayers;
  late Future<void> loading;
  bool dirty = true;
  bool hasWrites = false;

  IChunk(this.chunkX, this.chunkY, this.chunkZ);

  @override
  Future<void> onLoad() async {
    dirtyLayers = List.filled(ch, true);
    String s = ChunkSynth.synthChunk(cw + ch, ch, cd + ch);
    chunkMap = TiledComponent(
      await RenderableTiledMap.fromString(
        s,
        IsovoxGame.tileSize,
        useAtlas: true,
        ignoreFlip: true,
        prefix: 'assets/world/',
      ),
      priority: priority,
    );
  }

  int get cw => IsovoxGame.instance.chunkSize.x.toInt();

  int get ch => IsovoxGame.instance.chunkSize.y.toInt();

  int get cd => IsovoxGame.instance.chunkSize.z.toInt();

  @override
  void onMount() {
    double isoX = ((chunkX * cw) - (chunkZ * cd)) * (176 / 2);
    double isoY = ((chunkX * cw) + (chunkZ * cd)) * (101 / 2);
    isoY -= chunkY * 101 * ch;
    position = Vector2(isoX, isoY);
  }

  @override
  void update(double dt) async {
    if (dirty) {
      push();
      clearCache();
      dirty = false;
    }
  }

  void push() {
    int i;

    for (i = 0; i < ch; i++) {
      if (dirtyLayers[i]) {
        chunkMap.tileMap.renderableLayers[i].refreshCache();
        dirtyLayers[i] = false;
      }
    }
  }

  void setBlock(int x, int y, int z, IsovoxBlock block) {
    hasWrites = true;
    y = ch - 1 - y;
    int lh = (ch - 1) - y;
    x += y;
    z += y;
    final List<List<Gid>> td =
        (chunkMap.tileMap.map.layers[lh] as TileLayer).tileData!;
    if (td[z][x].tile != block.gid.tile) {
      td[z][x] = block.gid;
      dirtyLayers[lh] = true;
      dirty = true;
    }
  }

  IsovoxBlock getBlock(int x, int y, int z) {
    int lh = (ch - 1) - y;
    x += y;
    z += y;
    final List<List<Gid>> td =
        (chunkMap.tileMap.map.layers[lh] as TileLayer).tileData!;
    return BlockRegistry.instance.blocksById[td[z][x].tile - 1]!;
  }

  Image? _cache;

  void clearCache() {
    _cache = null;
  }

  double imageScale = 0.5;

  @override
  void render(Canvas canvas) {
    if (!hasWrites) {
      return;
    }

    if (_cache == null) {
      final recorder = PictureRecorder();
      final recordingCanvas = Canvas(recorder);

      recordingCanvas.scale(imageScale);
      renderableTileMap.render(recordingCanvas);
      final picture = recorder.endRecording();
      _cache = picture.toImageSync(
          (renderableTileMap.map.width *
                  renderableTileMap.map.tileWidth *
                  imageScale)
              .ceil(),
          (renderableTileMap.map.height *
                  renderableTileMap.map.tileHeight *
                  imageScale)
              .ceil());
      picture.dispose();
    }

    if (_cache != null) {
      // Draw the scaled image without further scaling
      canvas.scale(1 / imageScale);
      canvas.drawImage(_cache!, Offset.zero, _paint);
      canvas.scale(imageScale);
    }
  }

  RenderableTiledMap get renderableTileMap => chunkMap.tileMap;
}

Paint _paint = Paint();
