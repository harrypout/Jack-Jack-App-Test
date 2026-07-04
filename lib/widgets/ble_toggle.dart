import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';
import 'package:flutter/material.dart';

/// Design-system toggle: 44×26 track, 20px white thumb. Rebuilt as a custom
/// control (a scaled Material Switch distorts its thumb shadow and hit-slop);
/// same (value, onChanged) contract as the Switch it replaces.
class BLEToggle extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;
  const BLEToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          // Keep a Switch-like tap target around the 44×26 visual.
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: AnimatedContainer(
            duration: ThemeManager.durColor,
            width: 44,
            height: 26,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: ThemeManager.brFull,
              color: value ? ColorManager.sage : ColorManager.slate20,
            ),
            child: AnimatedAlign(
              duration: ThemeManager.durColor,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorManager.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F4A5568),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
