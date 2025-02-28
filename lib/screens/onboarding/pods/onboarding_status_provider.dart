import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'onboarding_status_provider.g.dart';

@riverpod
class OnboardingStatus extends _$OnboardingStatus {
  @override
  int build() => 0;

  Future<bool> next({bool skip = false}) async {
    if(skip){
      state = 2;
    }
    if (state < 2) {
      state = state + 1;
      return false;
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('onboarding_status', true);
      return true;
    }
  }
}
