class BLEUUIDS {
  String name;
  String service;
  String characteristic;
  BLEUUIDS({
    required this.name,
    required this.service,
    required this.characteristic,
  });

  @override
  String toString() =>
      'BLEUUIDS{name: $name, service: $service, characteristic: $characteristic}';
}