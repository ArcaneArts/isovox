import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:isovox/game/game.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GameWidget(game: IsovoxGame()));
}

Future<void> setupWindow() async {
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(
      WindowOptions(
          title: 'Isovox',
          size: Size(640, 480),
          backgroundColor: Color(0x00000000),
          fullScreen: false), () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
