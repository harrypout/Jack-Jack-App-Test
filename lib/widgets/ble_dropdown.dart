import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';

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
        color: ColorManager.tertiaryText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.only(
          left: 0,
          top: 12,
          bottom: 12,
          right: 4,
        ),
        isDense: false,
        visualDensity: VisualDensity(horizontal: 0, vertical: 0),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(2),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
