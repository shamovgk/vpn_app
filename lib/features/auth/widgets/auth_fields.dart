// lib/features/auth/widgets/auth_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vpn_app/ui/widgets/atoms/app_text_field.dart';
import 'package:vpn_app/core/extensions/string_ext.dart';

class UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  const UsernameField({super.key, required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Логин',
      leadingIcon: Icons.person,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      onSubmitted: onSubmitted,
      validator: (v) => v.validateUsername(),
    );
  }
}

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  const EmailField({super.key, required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Email',
      leadingIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      onChanged: (v) => controller.value = controller.value.copyWith(
        text: v.toLowerCase(),
        selection: TextSelection.collapsed(offset: v.length),
      ),
      onSubmitted: onSubmitted,
      validator: (v) => v.validateEmail(),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final String label;
  final int minLength;

  const PasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSubmitted,
    this.label = 'Пароль',
    this.minLength = 6,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      label: widget.label,
      leadingIcon: Icons.lock,
      trailingIcon: _visible ? Icons.visibility : Icons.visibility_off,
      onTrailingPressed: () => setState(() => _visible = !_visible),
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      obscureText: !_visible,
      onSubmitted: widget.onSubmitted,
      validator: (v) => v.validatePassword(min: widget.minLength),
    );
  }
}

class CodeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? exactLength;                 // если знаем точную длину (напр., 6)
  final int minLength;                    // иначе используем минимум
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCompleted;        // вызов при наборе exactLength
  final FocusNode? focusNode;

  const CodeField({
    super.key,
    required this.controller,
    this.label = 'Код',
    this.exactLength,
    this.minLength = 4,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onCompleted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      if (exactLength != null) LengthLimitingTextInputFormatter(exactLength),
    ];

    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      leadingIcon: Icons.verified,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: formatters,
      onSubmitted: onSubmitted,
      onChanged: (v) {
        if (exactLength != null && v.length == exactLength && onCompleted != null) {
          onCompleted!();
        }
      },
      validator: (v) => exactLength != null
          ? v.validateCodeExact(length: exactLength!)
          : v.validateCode(min: minLength),
    );
  }
}
