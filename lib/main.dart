import 'package:box_master/healthKitPermission.dart';
import 'package:box_master/listAvailableDevicesScreen.dart';
import 'package:box_master/showStatsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:health/health.dart';

late Health health;
void main() async {
  // if your terminal doesn't support color you'll see annoying logs like `\x1B[1;35m`
  FlutterBluePlus.setLogLevel(LogLevel.none, color: false);

  // optional
  FlutterBluePlus.logs.listen((String s) {
    //print(s);
  });
  WidgetsFlutterBinding.ensureInitialized();
  // Global Health instance
  health = Health();

  // configure the health plugin before use.
  await health.configure();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<bool> healthKidReady() async {
    bool healthKidInstalled =
        await health.getHealthConnectSdkStatus() ==
        HealthConnectSdkStatus.sdkAvailable;
    bool allPermissions =
        await GetHealthKitPermission.hasAllPermissions(health) ?? false;

    return healthKidInstalled && allPermissions;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Box Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      ),
      home: Scaffold(
        body: FutureBuilder(
          future: healthKidReady(),
          builder: (context, snapshot) {
            if (snapshot.hasData == false) {
              //show loading screen
              return Center(child: CircularProgressIndicator());
            } else {
              if (snapshot.data == true) {
                return HandleDevices();
              } else {
                return GetHealthKitPermission(health: health);
              }
            }
          },
        ),
      ),
    );
  }
}

class HandleDevices extends StatefulWidget {
  HandleDevices({super.key});
  @override
  State<HandleDevices> createState() => _HandleDevicesState();
}

class _HandleDevicesState extends State<HandleDevices> {
  DeviceController deviceController = DeviceController();
  bool isConnected = false;
  @override
  void initState() {
    super.initState();
    deviceController.addListener(() {
      setState(() {
        isConnected = deviceController.isConnected;
      });
    });
  }

  Widget showAvailableDevicesScreen() {
    return StreamBuilder(
      stream: FlutterBluePlus.adapterState,
      builder: (context, state) {
        if (state.data == BluetoothAdapterState.on) {
          return ListAvailableDevices(deviceController: deviceController);
        } else {
          return Scaffold(
            body: Center(
              child: Text(
                "Please turn on bluetooth",
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.red),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isConnected
        ? ShowCharacteristicValue(
          deviceController: deviceController,
          health: health,
        )
        : showAvailableDevicesScreen();
  }

  @override
  void dispose() {
    deviceController.dispose();
    super.dispose();
  }
}
