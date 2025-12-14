import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:health/health.dart';
import 'listAvailableDevicesScreen.dart';

class CharacteristicScanResult {
  CharacteristicScanResult(this.characteristic, this.found);
  late BluetoothCharacteristic? characteristic;
  bool found = false;
}

class ShowCharacteristicValue extends StatefulWidget {
  ShowCharacteristicValue({super.key, required this.deviceController, required this.health});
  DeviceController deviceController;
  Health health;

  @override
  State<ShowCharacteristicValue> createState() =>
      _ShowCharacteristicValueState();
}

class _ShowCharacteristicValueState extends State<ShowCharacteristicValue> {
  List<BluetoothService> services = [];
  String stringValue = "No data yet";
  double minCaloriesToOpenValues = 0;
  BluetoothCharacteristic? caloriesCharacteristic;
  BluetoothCharacteristic? minCaloriesToOpenCharacteristic;

  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String BURNED_CALORIES_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String MIN_CALORIES_TO_OPEN_UUID =
      "33aedfe5-62a7-4f57-aad2-00d409fcd44c";

  bool characteristicsNotFound = false;

  @override
  void initState() {
    var burnedCaloriesResult = getCharacteristic(
      SERVICE_UUID,
      BURNED_CALORIES_UUID,
    );
    burnedCaloriesResult.then((characteristic) {
      if (characteristic.found == false) {
        setState(() {
          characteristicsNotFound = true;
        });
      }
      caloriesCharacteristic = characteristic.characteristic;
      caloriesCharacteristic?.onValueReceived.listen((event) {
        setState(() {
          stringValue = String.fromCharCodes(event);
        });
      });

      if (caloriesCharacteristic != null) {
        caloriesCharacteristic?.read().then((value) {
          setState(() {
            stringValue = String.fromCharCodes(value);
          });
        });
      }
    });

    var minCaloriesResult = getCharacteristic(
      SERVICE_UUID,
      MIN_CALORIES_TO_OPEN_UUID,
    );
    minCaloriesResult.then((characteristic) {
      if (characteristic.found == false) {
        setState(() {
          characteristicsNotFound = true;
        });
      }
      minCaloriesToOpenCharacteristic = characteristic.characteristic;
      minCaloriesToOpenCharacteristic?.onValueReceived.listen((event) {
        setState(() {
          minCaloriesToOpenValues = double.parse(String.fromCharCodes(event));
        });
      });
      if (minCaloriesToOpenCharacteristic != null) {
        minCaloriesToOpenCharacteristic?.read().then((value) {
          setState(() {
            minCaloriesToOpenValues = double.parse(String.fromCharCodes(value));
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

  Future<CharacteristicScanResult> getCharacteristic(
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
        return CharacteristicScanResult(characteristic, true);
      }
    }
    return CharacteristicScanResult(null, false);
  }

  Future<double> getActiveBurnedCalories(
    DateTime startTime,
    DateTime endTime,
  ) async {
    double totalActiveBurnedCalories = 0;
    var entries = await widget.health.getHealthDataFromTypes(
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
      if (characteristicsNotFound == false) {
        return Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        );
      } else {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Text(
                  "The required characteristics were not found on the device",
                ),
                TextButton(
                  onPressed: () {
                    widget.deviceController.disconnectDevice();
                  },
                  child: Text("Disconnect"),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      double currentBurnedCalories = double.tryParse(stringValue) ?? 0;
      List<PieChartSectionData> entries = [
        PieChartSectionData(
          badgeWidget: Text("burned"),
          badgePositionPercentageOffset: -0.5,
          value: currentBurnedCalories,
          color: Colors.green,
        ),
      ];
      if (currentBurnedCalories < minCaloriesToOpenValues) {
        entries += [
          PieChartSectionData(
            badgeWidget: Text("to go"),
            badgePositionPercentageOffset: -0.5,
            value: minCaloriesToOpenValues - currentBurnedCalories,
            color: Colors.red,
          ),
        ];
      }

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Calories overview",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Padding(
                  padding: EdgeInsetsGeometry.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white70,
                          Colors.grey[350] ?? Colors.grey,
                          Colors.white70,
                        ],
                        begin: AlignmentGeometry.topLeft,
                        end: AlignmentGeometry.bottomRight,
                      ),
                      border: BoxBorder.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                      child: PieChart(PieChartData(sections: entries)),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    DateTime now = DateTime.now();
                    DateTime today = DateTime(now.year, now.month, now.day);
                    getActiveBurnedCalories(today, now).then((value) {
                      setState(() {
                        caloriesCharacteristic?.write(
                          value.toStringAsFixed(1).codeUnits,
                        );
                      });
                      if (caloriesCharacteristic != null) {
                        caloriesCharacteristic?.read().then((value) {
                          setState(() {
                            stringValue = String.fromCharCodes(value);
                          });
                        });
                      }

                      if (minCaloriesToOpenCharacteristic != null) {
                        minCaloriesToOpenCharacteristic?.read().then((value) {
                          setState(() {
                            minCaloriesToOpenValues = double.parse(
                              String.fromCharCodes(value),
                            );
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