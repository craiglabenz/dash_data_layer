import 'package:data_layer/data_layer.dart';
import 'package:data_layer_hive/data_layer_hive.dart';
import 'package:example/click.dart';

class ClickRepository extends Repository<Click> {
  ClickRepository(Future<void> hiveInit)
    : super(
        SourceList(
          bindings: Click.bindings,
          sources: [
            LocalMemorySource<Click>(bindings: Click.bindings),
            HiveSource<Click>(bindings: Click.bindings, hiveInit: hiveInit),
          ],
        ),
      );
}
