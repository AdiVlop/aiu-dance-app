import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final Color? fillColor;
  final bool filled;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final String? helperText;
  final String? errorText;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.focusNode,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.fillColor,
    this.filled = false,
    this.labelStyle,
    this.hintStyle,
    this.textStyle,
    this.helperText,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          style: widget.textStyle,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: widget.border ?? _getDefaultBorder(),
            enabledBorder: widget.enabledBorder ?? _getDefaultBorder(),
            focusedBorder: widget.focusedBorder ?? _getFocusedBorder(),
            errorBorder: widget.errorBorder ?? _getErrorBorder(),
            focusedErrorBorder: widget.focusedErrorBorder ?? _getFocusedErrorBorder(),
            fillColor: widget.fillColor,
            filled: widget.filled,
            labelStyle: widget.labelStyle,
            hintStyle: widget.hintStyle,
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  InputBorder _getDefaultBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    );
  }

  InputBorder _getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    );
  }

  InputBorder _getErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red[300]!),
    );
  }

  InputBorder _getFocusedErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red, width: 2),
    );
  }
}

// Predefined text field styles for common use cases
class CustomTextFields {
  static CustomTextField email({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      labelText: labelText ?? 'Email',
      hintText: hintText ?? 'Introduceți adresa de email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? _emailValidator,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.email_outlined),
    );
  }

  static CustomTextField password({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      labelText: labelText ?? 'Parolă',
      hintText: hintText ?? 'Introduceți parola',
      controller: controller,
      obscureText: true,
      validator: validator ?? _passwordValidator,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.lock_outlined),
    );
  }

  static CustomTextField name({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      labelText: labelText ?? 'Nume',
      hintText: hintText ?? 'Introduceți numele',
      controller: controller,
      textCapitalization: TextCapitalization.words,
      validator: validator ?? _nameValidator,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.person_outlined),
    );
  }

  static CustomTextField phone({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      labelText: labelText ?? 'Telefon',
      hintText: hintText ?? 'Introduceți numărul de telefon',
      controller: controller,
      keyboardType: TextInputType.phone,
      validator: validator ?? _phoneValidator,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.phone_outlined),
    );
  }

  static CustomTextField search({
    String? hintText,
    TextEditingController? controller,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return CustomTextField(
      hintText: hintText ?? 'Căutare...',
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  static CustomTextField amount({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      labelText: labelText ?? 'Sumă',
      hintText: hintText ?? '0.00',
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator ?? _amountValidator,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.attach_money),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }

  // Validation functions
  static String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email-ul este obligatoriu';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Introduceți un email valid';
    }
    return null;
  }

  static String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Parola este obligatorie';
    }
    if (value.length < 6) {
      return 'Parola trebuie să aibă cel puțin 6 caractere';
    }
    return null;
  }

  static String? _nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numele este obligatoriu';
    }
    if (value.length < 2) {
      return 'Numele trebuie să aibă cel puțin 2 caractere';
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numărul de telefon este obligatoriu';
    }
    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
      return 'Introduceți un număr de telefon valid';
    }
    return null;
  }

  static String? _amountValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Suma este obligatorie';
    }
    if (double.tryParse(value) == null) {
      return 'Introduceți o sumă validă';
    }
    if (double.parse(value) <= 0) {
      return 'Suma trebuie să fie mai mare decât 0';
    }
    return null;
  }
} 