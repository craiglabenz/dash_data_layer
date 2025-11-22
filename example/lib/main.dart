import 'package:example/click.dart';
import 'package:example/hive/hive_registrar.g.dart';
import 'package:example/click_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

late Future<void> hiveInit;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.loggerName}][${record.level.name}]: ${record.time}: ${record.message}',
    );
  });

  hiveInit = Hive.initFlutter().then((_) {
    try {
      Hive.registerAdapters();
      // ignore: avoid_print
      print('Hive initialized!');
      return;
    } on Exception catch (e, st) {
      // ignore: avoid_print
      print('Failed to initialize Hive: $e :: $st');
      return;
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'Shadcn Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorSchemes.lightBlue,
      ),
      home: const MyHomePage(title: 'Shadcn Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ClickRepository _clickRepository;

  List<Click> clicks = [];

  @override
  void initState() {
    super.initState();
    _clickRepository = ClickRepository(hiveInit);
    _refreshClicks();
  }

  Future<void> _incrementCounter() async {
    await _clickRepository.setItem(
      Click(delta: 1, clickedAt: DateTime.now()),
    );
    _refreshClicks();
  }

  void _refreshClicks() {
    _clickRepository.getItems(allLocal: true).then(
      (items) {
        setState(() => clicks = items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = clicks.fold<int>(
      0,
      (previousValue, element) => previousValue + element.delta,
    );
    const heavyShadows = [
      BoxShadow(
        color: Color(0x88000000),
        offset: Offset(0, 1),
        blurRadius: 3,
      ),
    ];
    const lightShadows = [
      BoxShadow(
        color: Color(0x44000000),
        offset: Offset(0, 1),
        blurRadius: 3,
      ),
    ];
    return Scaffold(
      headers: [AppBar(title: Text(widget.title))],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          children: [
            Card(
              boxShadow: heavyShadows,
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .center,
                children: [
                  Center(
                    child: Text('You pressed the button $count times').p,
                  ),
                  PrimaryButton(
                    onPressed: _incrementCounter,
                    child: Text('Increment'),
                  ),
                ],
              ),
            ),
            ...clicks.map<Widget>(
              (click) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  boxShadow: lightShadows,
                  child: Row(
                    mainAxisAlignment: .spaceAround,
                    crossAxisAlignment: .center,
                    children: [
                      Text(
                        'Clicked at ${click.clickedAt}',
                      ).p,
                      IconButton.destructive(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _clickRepository.delete(click.id);
                          _refreshClicks();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
