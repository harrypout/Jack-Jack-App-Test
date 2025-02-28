import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'navigation_provider.g.dart';

@riverpod
class Navigation extends _$Navigation {
  @override
  int build() => 0; // Initial value is false

  void toggle(int index) => state = index;
}
