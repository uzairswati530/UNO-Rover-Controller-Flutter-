import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'device.dart';

class SelectBondedDevicePage extends StatefulWidget {
  final bool checkAvailability;
  final Function onChatPage;
  final int rssi;

  const SelectBondedDevicePage({
    this.checkAvailability = true,
    required this.onChatPage,
    required this.rssi,
  });

  @override
  _SelectBondedDevicePage createState() => _SelectBondedDevicePage();
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}

class _DeviceWithAvailability {
  final BluetoothDevice device;
  _DeviceAvailability availability;
  int rssi;

  _DeviceWithAvailability(this.device, this.availability, this.rssi);
}

class _SelectBondedDevicePage extends State<SelectBondedDevicePage> {
  List<_DeviceWithAvailability> devices = [];
  late StreamSubscription<BluetoothDiscoveryResult>
      _discoveryStreamSubscription;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    FlutterBluetoothSerial.instance.getBondedDevices().then((bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map((device) => _DeviceWithAvailability(
                device,
                _isDiscovering
                    ? _DeviceAvailability.maybe
                    : _DeviceAvailability.yes,
                widget.rssi))
            .toList();
      });
    });
  }

  void _restartDiscovery() {
    setState(() {
      _isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _discoveryStreamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        var deviceIndex =
            devices.indexWhere((device) => device.device == r.device);
        if (deviceIndex != -1) {
          devices[deviceIndex].availability = _DeviceAvailability.yes;
          devices[deviceIndex].rssi = r.rssi;
        }
      });
    });

    _discoveryStreamSubscription.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    _discoveryStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDeviceListEntry> list = devices
        .map(
          (device) => BluetoothDeviceListEntry(
            device: device.device,
            onTap: () {
              widget.onChatPage(device.device);
            },
          ),
        )
        .toList();
    return ListView(
      children: list,
    );
  }
}
