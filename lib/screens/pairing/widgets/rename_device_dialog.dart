import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jackjack/services/device_name_manager.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/widgets/ble_bottom_sheet.dart';
import 'package:jackjack/widgets/ble_filled_button.dart';
import 'package:jackjack/widgets/ble_outlined_button.dart';
import 'package:jackjack/widgets/ble_text_form_field.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class RenameDeviceDialog extends ConsumerStatefulWidget {
  final DiscoveredDevice device;

  const RenameDeviceDialog({super.key, required this.device});

  @override
  ConsumerState<RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends ConsumerState<RenameDeviceDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final deviceNamesNotifier = ref.read(deviceNamesProvider.notifier);
    final currentName = deviceNamesNotifier.getDeviceName(widget.device.id);
    _nameController = TextEditingController(
      text: currentName ?? widget.device.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceNamesNotifier = ref.read(deviceNamesProvider.notifier);
      await deviceNamesNotifier.setDeviceName(
        widget.device.id,
        _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error if needed
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BLEBottomSheet(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset("assets/svgs/rename.svg"),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Rename Device",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: ColorManager.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Give your device a custom name that's easy to remember",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: ColorManager.secondaryText,
                  ),
                ),
                const SizedBox(height: 24),

                BleTextFormFieldWithTitle(
                  title: "Device Name",
                  controller: _nameController,
                  hintText: "Enter device name",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Device name cannot be empty";
                    }
                    if (value.trim().length > 30) {
                      return "Device name must be 30 characters or less";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 16,
                    children: [
                      Expanded(
                        child: BLEOutlinedButton(
                          data: "Cancel",
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                  },
                          maxButton: true,
                        ),
                      ),
                      Expanded(
                        child: BLEFilledButton(
                          data: _isLoading ? "Saving..." : "Save",
                          onPressed: _isLoading ? null : _saveName,
                          maxButton: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
