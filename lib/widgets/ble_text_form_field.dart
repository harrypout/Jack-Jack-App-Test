import 'package:flutter/material.dart';
import 'package:jackjack/utils/color_manager.dart';

class BleTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool obscure;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? minLines;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  const BleTextFormField({
    super.key,
    this.controller,
    this.keyboardType,
    this.hintText,
    this.obscure = false,
    this.suffixIcon,
    this.prefixIcon,
    this.minLines,
    this.maxLines,
    this.onChanged,
    this.validator,
    this.focusNode,
  });

  @override
  State<BleTextFormField> createState() => _BleTextFormFieldState();
}

class _BleTextFormFieldState extends State<BleTextFormField> {
  OutlineInputBorder customOutlineInputBorder({
    BorderSide borderSide = const BorderSide(),
  }) {
    return OutlineInputBorder(
      borderSide: borderSide,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  String showIcon = "assets/images/show.png";
  String hideIcon = "assets/images/hide.png";
  String selected = "assets/images/show.png";
  bool obscuredText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscure && obscuredText && widget.controller != null,
      minLines: widget.minLines,
      maxLines: widget.maxLines ?? 1,
      enableSuggestions: false,
      onChanged:
          widget.onChanged ??
          (val) {
            setState(() {});
          },
      validator: widget.validator,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        filled: true,
        fillColor: ColorManager.white,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: ColorManager.gaugeAxisLabelText,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        suffixIconConstraints:
            widget.suffixIcon != null
                ? const BoxConstraints(maxWidth: 38, maxHeight: 24)
                : (widget.obscure
                    ? const BoxConstraints(maxWidth: 38, maxHeight: 24)
                    : null),
        suffixIcon:
            widget.suffixIcon ??
            (widget.controller != null
                ? ((widget.obscure && widget.controller!.text.isNotEmpty)
                    ? Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (obscuredText) {
                              selected = hideIcon;
                              obscuredText = false;
                            } else {
                              selected = showIcon;
                              obscuredText = true;
                            }
                          });
                        },
                        child: Image.asset(selected, width: 24, height: 24),
                      ),
                    )
                    : null)
                : null),
        prefixIcon: widget.prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        // labelText: "Age",
        border: customOutlineInputBorder(),
        enabledBorder: customOutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorManager.containerBorder,
            width: 2.0,
          ),
        ),
        focusedBorder: customOutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorManager.containerBorder,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}

class BleTextFormFieldWithTitle extends StatelessWidget {
  final String title;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final int? minLines;
  final int? maxLines;
  final bool obscure;
  final void Function(String)? onChanged;
  const BleTextFormFieldWithTitle({
    super.key,
    required this.title,
    this.controller,
    this.keyboardType,
    this.hintText,
    this.minLines,
    this.maxLines,
    this.obscure = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: ColorManager.quaternaryText,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BleTextFormField(
            controller: controller,
            keyboardType: keyboardType,
            hintText: hintText,
            obscure: obscure,
            minLines: minLines,
            maxLines: maxLines,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
