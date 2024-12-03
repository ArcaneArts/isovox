import 'dart:math';

import 'package:flame/components.dart';
import 'package:isovox/game/game.dart';
import 'package:isovox/game/world/chunk.dart';
import 'package:isovox/game/world/generator.dart';
import 'package:toxic/extensions/iterable.dart';

class IsovoxWorld extends World {
  late final ChunkGenerator generator;
  late int viewDistance = 10;
  late int concurrentLoads = 1;
  int position = 0;
  Set<int> view = {};
  Set<int> loading = {};
  Map<int, IChunk> loadedChunks = {};
  bool _updateView = true;
  int energy = 0;
  int cacheCooldown = 0;
  int chunkLSize = 100;

  @override
  Future<void> onLoad() async {
    generator = TypicalGenerator();
    chunkLSize = (IsovoxGame.instance.chunkSize.length / 2).round();
    print("CLSize $chunkLSize");
  }

  @override
  void update(double dt) {
    energy = min(energy += 3, 100);
    cacheCooldown++;
    updateLoaderPosition();

    if (_updateView) {
      (int, int) cp = getCoords(position);
      _updateView = false;
      view.clear();
      for (int x = -viewDistance; x < viewDistance; x++) {
        for (int z = -viewDistance; z < viewDistance; z++) {
          int index = getIndex(cp.$1 + x, cp.$2 + z);
          view.add(index);
        }
      }
    }

    bool needLoad = energy > chunkLSize &&
        loading.length < concurrentLoads &&
        view.any((element) => !loadedChunks.containsKey(element));

    if (needLoad) {
      for (int i in view.sorted((a, b) {
        (int, int) aa = getCoords(a);
        (int, int) bb = getCoords(b);
        (int, int) p = getCoords(position);

        double da = (aa.$1 - p.$1).abs() + (aa.$2 - p.$2).abs().toDouble();
        double db = (bb.$1 - p.$1).abs() + (bb.$2 - p.$2).abs().toDouble();

        return sqrt(da).compareTo(sqrt(db));
      })) {
        if (!loading.contains(i) && !loadedChunks.containsKey(i)) {
          loading.add(i);
          (int, int) coords = getCoords(i);
          IChunk c = IChunk(coords.$1, 0, coords.$2);
          c.priority = i;
          add(c);
          energy -= chunkLSize;
          c.loaded.then((_) => generator.generate(c).then((_) {
                loadedChunks[i] = c;
                loading.remove(i);
                print("Loaded $i");
              }));
          break;
        }
      }
    }

    if (loadedChunks.length > view.length &&
        loadedChunks.keys.any((element) => !view.contains(element))) {
      for (int i in loadedChunks.keys) {
        if (!view.contains(i)) {
          IChunk c = loadedChunks.remove(i)!;
          remove(c);
          energy--;
          break;
        }
      }
    }
  }

  Vector2 getBlockPositionFromScreenSpace(Vector2 v) {
    double y = -v.y / (101);
    final double isoScaleX = 176 / 2;
    final double isoScaleY = 101 / 2;
    double x = (v.x / isoScaleX + v.y / isoScaleY) / (2);
    double z = (-v.x / isoScaleX + v.y / isoScaleY) / (2);

    return Vector2(x.round().toDouble(), z.round().toDouble());
  }

  void updateLoaderPosition() {
    Vector2 cam = IsovoxGame.instance.cameraPosition;
    Vector2 block = getBlockPositionFromScreenSpace(cam);
    int index = getIndex((block.x / IsovoxGame.instance.chunkSize.x).floor(),
        (block.y / IsovoxGame.instance.chunkSize.z).floor());
    if (index != position) {
      position = index;
      _updateView = true;
    }
  }

  int getIndex(int x, int z) {
    return (x & 0xFFFFFF) | ((z & 0xFFFFFF) << 24);
  }

  (int, int) getCoords(int index) {
    int x = index & 0xFFFFFF;
    int z = (index >> 24) & 0xFFFFFF;
    return (x, z);
  }
}
