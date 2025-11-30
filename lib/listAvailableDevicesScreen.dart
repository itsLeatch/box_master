import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceController extends ChangeNotifier{
  BluetoothDevice? _connectedDevice; 
  StreamSubscription<dynamic>? _connectionStateSubscription;
  //set connected device and notify listeners
  void setConnectedDevice(BluetoothDevice device){
    _connectedDevice = device;
    _connectionStateSubscription = device.connectionState.listen((event) {
      if(event == BluetoothConnectionState.disconnected){
        _connectedDevice = null;
        notifyListeners();
      }
      _connectionStateSubscription?.cancel();
    });
    notifyListeners();
  }

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice?.isConnected ?? false;

}


class ListAvailableDevices extends StatefulWidget {
  const ListAvailableDevices({super.key, required this.deviceController});

  final DeviceController deviceController;

  @override
  State<ListAvailableDevices> createState() => _ListAvailableDevicesState();
}

class _ListAvailableDevicesState extends State<ListAvailableDevices> {
  List<ScanResult> availableDevices = [];

    @override
  void initState() {
    super.initState();
    startScan();
    
  }


  void startScan({Duration timeToScan = const Duration(seconds: 15)}) async {
    var subscription = FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        availableDevices = results;
        print(availableDevices);
      });
    });

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(timeout: timeToScan);

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  void connect(BluetoothDevice device) async {
    await device.connect(license: License.free, autoConnect: true, mtu: null);

    // wait until connection
    //  - when using autoConnect, connect() always returns immediately, so we must
    //    explicity listen to `device.connectionState` to know when connection occurs
    await device.connectionState.where((val) {
      bool result = false;
      setState(() {
        result = val == BluetoothConnectionState.connected;
        widget.deviceController.setConnectedDevice(device);
      });
      return result;
    }).first;
  }

  void disconnect(BluetoothDevice device) async {
    device.disconnect().then((value) {
      setState(() {});
    });
  }

  Widget buildDeviceListTile(ScanResult r) {
    final device = r.device;
    final isConnected = widget.deviceController.connectedDevice?.remoteId == device.remoteId;

    return ListTile(
      title: Text(device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString()),
      subtitle: Text(device.remoteId.toString()),
      trailing: isConnected
          ? ElevatedButton(
              onPressed: () => disconnect(device), child: Text("Disconnect"))
          : ElevatedButton(
              onPressed: () => connect(device), child: Text("Connect")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Devices"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              startScan();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: availableDevices.length,
        itemBuilder: (context, index) {
          return buildDeviceListTile(availableDevices[index]);
        },
      ),
    );
  }
}