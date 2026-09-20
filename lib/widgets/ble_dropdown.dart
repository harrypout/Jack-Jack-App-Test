import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';

class DropdownWithMap<T> extends StatelessWidget {
  final String hintText;
  final Map<String, T> items;
  final TextEditingController? controller;
  final void Function(T?)? onSelected;
  final T? initialSelection;
  final bool enableSearch;
  final double? width;
  const DropdownWithMap({
    super.key,
    required this.hintText,
    required this.items,
    this.onSelected,
    this.controller,
    this.initialSelection,
    this.width,
    this.enableSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hintText,
      child: DropdownMenu<T>(
        menuHeight: 320,
        width: width,
        initialSelection: initialSelection,
        controller: controller,
        requestFocusOnTap: false,
        enableFilter: false,
        enableSearch: enableSearch,
        onSelected: onSelected,
        dropdownMenuEntries: [
          for (final entry in items.entries)
            DropdownMenuEntry(
              label: entry.key,
              value: entry.value,
              style: MenuItemButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                foregroundColor: ColorManager.slate,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        textStyle: const TextStyle(
          color: ColorManager.slate,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
        selectedTrailingIcon: const Icon(
          Icons.keyboard_arrow_up_rounded,
          size: 22,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ColorManager.background,
          border: const OutlineInputBorder(
            borderRadius: ThemeManager.brMd,
            borderSide: BorderSide(color: ColorManager.slate20),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: ThemeManager.brMd,
            borderSide: BorderSide(color: ColorManager.slate20),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: ThemeManager.brMd,
            borderSide: BorderSide(color: ColorManager.sage, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          constraints: const BoxConstraints(minHeight: 48),
        ),
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(ColorManager.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: ThemeManager.brMd),
          ),
        ),
      ),
    );
  }
}
