
import 'package:ble/models/ble_uuids.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BLEServiceType { getInt, setInt, stream }

class BLEService {
  BluetoothService? service;
  BluetoothCharacteristic? characteristic;
  BLEServiceType type;
  BLEUUIDS uuid;
  dynamic data;
  BLEService({
    this.service,
    this.characteristic,
    required this.uuid,
    required this.type,
    this.data,
  });
  BLEService copyWith({
    BluetoothService? service,
    BluetoothCharacteristic? characteristic,
    BLEUUIDS? uuid,
    BLEServiceType? type,
    dynamic data,
  }) {
    return BLEService(
      service: service ?? this.service,
      characteristic: characteristic ?? this.characteristic,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  static Future<BLEService> getService(
    List<BluetoothService> services,
    BLEUUIDS targetService,
    BLEServiceType serviceType,
  ) async {
    BLEService newService = BLEService(
      uuid: targetService,
      type: serviceType,
      data: serviceType == BLEServiceType.stream ? Stream.value(0) : 0,
    );
    try {
      print(services);
      BluetoothCharacteristic? soundCharacteristic;
      print("${targetService.name} service");
      BluetoothService service = services.firstWhere(
        (s) => s.uuid.toString() == targetService.service,
        orElse: () => throw Exception("Service not found"),
      );
      print("${targetService.name} characteristic");
      // Find the characteristic
      soundCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == targetService.characteristic,
        orElse: () => throw Exception("Characteristic not found"),
      );

      newService = newService.copyWith(
        service: service,
        characteristic: soundCharacteristic!,
      );
      await newService.getValue();
    } catch (e, s) {
      print("$e\n$s");
    }
    return newService;
  }

  Future<void> getValue() async {
    if (type == BLEServiceType.stream) {
      if (data == null && characteristic == null) {
        data = Stream.value(0).asBroadcastStream();
      } else {
        if (characteristic == null) {
          data = Stream.value(0).asBroadcastStream();
        } else {
          await characteristic!.setNotifyValue(true);
          var newData =
              characteristic!.lastValueStream
                  .map((List<int> values) => values.isNotEmpty ? values[0] : 0)
                  .asBroadcastStream();

          if (data != null) {
            if (!identical(data, newData)) {
              data = newData;
            }
          } else {
            data = newData;
          }
          print("streamset");
        }
      }
    } else if (type == BLEServiceType.getInt) {
      print("get ${uuid.name} int");
      List<int> byteData = await characteristic!.read();
      byteData.forEach((element) {
        print("byteData: $element");
      });
      String textData = String.fromCharCodes(byteData);
      print("Received text: $textData");
      data = byteData.isNotEmpty ? byteData[0] : 0;
    }
  }

  Future<void> setValue(int value) async {
    print(type);
    if (type == BLEServiceType.setInt) {
      print("Setting");
      print("set ${uuid.name} int");
      await characteristic!.write([value]);
    }
  }
}