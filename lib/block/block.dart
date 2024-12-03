import 'package:flame_tiled/flame_tiled.dart';

class IsovoxBlock {
  final String name;
  final int id;
  final Gid gid;

  IsovoxBlock(this.name, this.id) : gid = Gid.fromInt(id + 1);
}
