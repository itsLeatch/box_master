import 'package:box_master/healthKitPermission.dart';
import 'package:box_master/listAvailableDevicesScreen.dart';
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
      title: 'Box Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FutureBuilder(
        future: healthKidReady(),
        builder: (context, snapshot) {
          if (snapshot.hasData == false) {
            //show loading screen
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data == true) {
              return HandleDevices();
            } else {
              return TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return GetHealthKitPermission(health: health);
                          },
                        ),
                      )
                      .then((value) {
                        setState(() {
                          //update
                        });
                      });
                },
                child: Text("Get Permission"),
              );
            }
          }
        },
      ),
    );
  }
}

class ShowCharacteristicValue extends StatefulWidget {
  ShowCharacteristicValue({super.key, required this.deviceController});
  DeviceController deviceController;

  @override
  State<ShowCharacteristicValue> createState() =>
      _ShowCharacteristicValueState();
}

class _ShowCharacteristicValueState extends State<ShowCharacteristicValue> {
  List<BluetoothService> services = [];
  String stringValue = "No data yet";
  BluetoothCharacteristic? caloriesCharacteristic;

  @override
  void initState() {
    getCharacteristic(
      "4fafc201-1fb5-459e-8fcc-c5c9c331914b",
      "beb5483e-36e1-4688-b7f5-ea07361b26a8",
    ).then((characteristic) {
      caloriesCharacteristic = characteristic;
      caloriesCharacteristic?.onValueReceived.listen((event) {
        setState(() {
          stringValue = String.fromCharCodes(event);
        });
      });

      setState(() {
        stringValue = "No matching characteristic found!";
      });
      if (caloriesCharacteristic != null) {
        caloriesCharacteristic?.read().then((value) {
          setState(() {
            stringValue = String.fromCharCodes(value);
          });
        });
      }
    });
    super.initState();
  }

  Future<bool> updateServices() async {
    services =
        await widget.deviceController.connectedDevice!.discoverServices();
    return true;
  }

  Future<BluetoothCharacteristic?> getCharacteristic(
    String serviceUUID,
    String characteristicUUID,
  ) async {
    await updateServices();
    List<BluetoothCharacteristic> bluetoothCharacteristics = [];

    for (var service in services) {
      if (service.uuid == Guid.fromString(serviceUUID)) {
        bluetoothCharacteristics = service.characteristics;
      }
    }

    for (var characteristic in bluetoothCharacteristics) {
      if (characteristic.uuid == Guid.fromString(characteristicUUID)) {
        return characteristic;
      }
    }
    return null;
  }

  Future<double> getActiveBurnedCalories(
    DateTime startTime,
    DateTime endTime,
  ) async {
    double totalActiveBurnedCalories = 0;
    var entries = await health.getHealthDataFromTypes(
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: startTime,
      endTime: endTime,
    );
    for (var entry in entries) {
      totalActiveBurnedCalories +=
          (entry.value as NumericHealthValue).numericValue.toDouble();
    }
    return totalActiveBurnedCalories;
  }

  @override
  Widget build(BuildContext context) {
    if (caloriesCharacteristic == null) {
      return Scaffold(body: SafeArea(child: Text(stringValue)));
    } else {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stringValue),
                TextButton(
                  onPressed: () {
                    DateTime now = DateTime.now();
                    DateTime today = DateTime(now.year, now.month, now.day);
                    getActiveBurnedCalories(today, now).then((value) {
                      print(value);
                      setState(() {
                        caloriesCharacteristic?.write(value.toString().codeUnits);
                      });
                      if (caloriesCharacteristic != null) {
                        caloriesCharacteristic?.read().then((value) {
                          setState(() {
                            stringValue = String.fromCharCodes(value);
                          });
                        });
                      }
                    });
                  },
                  child: Text("Update"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
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
          return Scaffold(body: Text("Please turn on bluetooth"));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isConnected
        ? ShowCharacteristicValue(deviceController: deviceController)
        : showAvailableDevicesScreen();
  }

  @override
  void dispose() {
    deviceController.dispose();
    super.dispose();
  }
}
