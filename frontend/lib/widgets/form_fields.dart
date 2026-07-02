import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card personalizada con diseño Flat Design 2.0
class MedHelpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  const MedHelpCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.backgroundColor,
    this.elevation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? AppColors.surface,
      elevation: elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Campo de texto reutilizable con validación
class MedHelpTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;

  const MedHelpTextField({
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    super.key,
  });

  @override
  State<MedHelpTextField> createState() => _MedHelpTextFieldState();
}

class _MedHelpTextFieldState extends State<MedHelpTextField> {
  late FocusNode _focusNode;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      focusNode: _focusNode,
      validator: (value) {
        final error = widget.validator?.call(value);
        setState(() => _showError = error != null);
        return error;
      },
      onChanged: (_) {
        if (_showError) setState(() => _showError = false);
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                icon: Icon(widget.suffixIcon),
                onPressed: widget.onSuffixIconTap,
              )
            : null,
      ),
    );
  }
}

/// Selector de tiempo (time picker) con validación
class TimePickerField extends StatefulWidget {
  final String label;
  final TimeOfDay? initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const TimePickerField({
    required this.label,
    required this.onTimeChanged,
    this.initialTime,
    super.key,
  });

  @override
  State<TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<TimePickerField> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
          widget.onTimeChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          _selectedTime.format(context),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Selector (dropdown) para frecuencias, períodos del día, etc.
class MedHelpDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T?) onChanged;

  const MedHelpDropdown({
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    super.key,
  });

  @override
  State<MedHelpDropdown<T>> createState() => _MedHelpDropdownState<T>();
}

class _MedHelpDropdownState<T> extends State<MedHelpDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: widget.value,
      initialValue: widget.value,
      items: widget.items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(widget.itemLabel(item)),
              ))
          .toList(),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle),
      ),
    );
  }
}
