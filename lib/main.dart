import 'package:box_master/listAvailableDevicesScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  // if your terminal doesn't support color you'll see annoying logs like `\x1B[1;35m`
  FlutterBluePlus.setLogLevel(LogLevel.none, color: false);

  // optional
  FlutterBluePlus.logs.listen((String s) {
    //print(s);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
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
      if (characteristic != null) {
        characteristic.read().then((value) {
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

  @override
  Widget build(BuildContext context) {
    if (caloriesCharacteristic == null) {
      return Scaffold(body: SafeArea(child: Text(stringValue)));
    } else {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Text(stringValue),
              TextField(
                onSubmitted: (value) {
                  setState(() {
                    caloriesCharacteristic?.write(value.codeUnits);
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
          return Text("Please turn on bluetooth");
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
