import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:isovox/block/block_registry.dart';
import 'package:isovox/game/world/world.dart';

class IsovoxGame extends FlameGame<IsovoxWorld> with KeyboardEvents {
  static late IsovoxGame instance;
  static Vector2 tileSize = Vector2(176, 101);
  // Config
  late double movementSpeed = 50;
  late double zoomSpeed = 0.3;
  late double zoom = 0.2;
  late double zoomVelocity = 0;
  late Vector2 cameraPosition = Vector2(0, 0);
  late Vector2 cameraVelocity = Vector2(0, 0);
  late Set<LogicalKeyboardKey> keysPressed = {};
  late BlockRegistry blockRegistry;
  late Vector3 chunkSize = Vector3(8, 32, 8);

  IsovoxGame()
      : super(
            world: IsovoxWorld(),
            camera: CameraComponent.withFixedResolution(
              width: 176 * 28,
              height: 176 * 14,
            ));

  @override
  Future<void> onLoad() async {
    instance = this;
    blockRegistry = await BlockRegistry.load();
    camera.viewfinder
      ..zoom = zoom
      ..anchor = Anchor.center;
    add(FpsTextComponent(decimalPlaces: 0));
  }

  @override
  void update(double dt) {
    super.update(dt);
    bool zoomIn = keysPressed.contains(LogicalKeyboardKey.equal);
    bool zoomOut = keysPressed.contains(LogicalKeyboardKey.minus);
    bool up = keysPressed.contains(LogicalKeyboardKey.keyW);
    bool left = keysPressed.contains(LogicalKeyboardKey.keyA);
    bool right = keysPressed.contains(LogicalKeyboardKey.keyD);
    bool down = keysPressed.contains(LogicalKeyboardKey.keyS);
    bool space = keysPressed.contains(LogicalKeyboardKey.space);
    cameraVelocity += Vector2(
          (right ? 1 : 0) - (left ? 1 : 0),
          (down ? 1 : 0) - (up ? 1 : 0),
        ) *
        movementSpeed;
    double magnitude = cameraVelocity.length;
    cameraPosition += cameraVelocity.normalized() * magnitude * dt;
    cameraVelocity *= 0.99;
    zoomVelocity +=
        (((zoomIn ? 0.1 : 0) - (zoomOut ? 0.1 : 0)) * zoomSpeed * 0.01)
            .clamp(-zoomSpeed, zoomSpeed);
    zoom *= (zoomVelocity + 1);
    zoom = zoom.clamp(0.15, 2);
    camera.viewfinder.zoom = zoom;
    zoomVelocity *= 0.99;
    camera.moveTo(cameraPosition);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    this.keysPressed = keysPressed;
    return KeyEventResult.ignored;
  }

  Future<TiledComponent> loadMap(String mapName) => TiledComponent.load(
      ignoreFlip: true,
      useAtlas: true,
      prefix: 'assets/world/',
      '$mapName.tmx',
      Vector2(176, 101));
}
