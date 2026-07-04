import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';
import 'package:jackjack/utils/theme_manager.dart';

class DropdownWithMap<T> extends StatefulWidget {
  String hintText;
  Map items;
  TextEditingController? controller;
  void Function(T?)? onSelected;
  T? initialSelection;
  bool enableSearch;
  double? width;
  DropdownWithMap({
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
  State<DropdownWithMap<T>> createState() => _DropdownWithMap<T>();
}

class _DropdownWithMap<T> extends State<DropdownWithMap<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      menuHeight: 210,
      width: widget.width,
      initialSelection: widget.initialSelection,
      controller: widget.controller,
      requestFocusOnTap: false,
      enableFilter: false,
      enableSearch: widget.enableSearch,
      onSelected: widget.onSelected,
      dropdownMenuEntries: List.generate(
        widget.items.length,
        (i) => DropdownMenuEntry(
          label: (widget.items.entries.toList())[i].key,
          value: (widget.items.entries.toList())[i].value,
        ),
      ),
      textStyle: const TextStyle(
        color: ColorManager.slate70,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
      trailingIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: ColorManager.slate60,
      ),
      selectedTrailingIcon: const Icon(
        Icons.keyboard_arrow_up_rounded,
        size: 18,
        color: ColorManager.slate60,
      ),
      // Dropdown chip: 1px slate-20 border, radius-md.
      // (The InputDecorationTheme.visualDensity param the previous version
      // set does not exist in Flutter 3.32.7, and its (0,0) value was the
      // mobile default anyway.)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: ThemeManager.brMd,
          borderSide: const BorderSide(color: ColorManager.slate20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ThemeManager.brMd,
          borderSide: const BorderSide(color: ColorManager.slate20),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ThemeManager.brMd,
          borderSide: const BorderSide(color: ColorManager.sage),
        ),
        contentPadding: const EdgeInsets.only(
          left: 10,
          top: 12,
          bottom: 12,
          right: 4,
        ),
        isDense: false,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(2),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: ThemeManager.brMd),
        ),
      ),
    );
  }
}
