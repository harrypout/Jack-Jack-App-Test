import 'package:jackjack/utils/color_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastManager {
  static Future<void> show(String message) async {
    await Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: ColorManager.slate,
      textColor: ColorManager.white,
      fontSize: 16.0,
    );
  }
}
