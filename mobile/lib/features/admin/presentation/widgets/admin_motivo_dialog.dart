import 'package:flutter/material.dart';

Future<String?> showAdminMotivoDialog(
  BuildContext context, {
  required String title,
  String hint = 'Describe el motivo…',
  int minLength = 10,
  bool multiline = true,
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: multiline ? 4 : 1,
          decoration: InputDecoration(hintText: hint),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length < minLength) {
              return 'Mínimo $minLength caracteres.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(ctx, controller.text.trim());
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}
