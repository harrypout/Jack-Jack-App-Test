import 'package:flutter/material.dart';

class DropdownWithMap<T> extends StatefulWidget {
  String hintText;
  Map items;
  TextEditingController? controller;
  void Function(T?)? onSelected;
  T? initialSelection;
  bool enableSearch;
  double? width;
  DropdownWithMap(
      {super.key,
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
      menuHeight: 200,
      width: widget.width,
      initialSelection: widget.initialSelection,
      controller: widget.controller,
      requestFocusOnTap: false,
      enableFilter: false,
      enableSearch: widget.enableSearch,
      // label: Text(widget.hintText),
      onSelected: widget.onSelected,
      dropdownMenuEntries: List.generate(
        widget.items.length,
            (i) => DropdownMenuEntry(
          label: (widget.items.entries.toList())[i].key,
         value : (widget.items.entries.toList())[i].value,
        ),
      ),
    );
  }
}