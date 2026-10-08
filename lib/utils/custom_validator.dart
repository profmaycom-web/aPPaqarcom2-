import 'package:material_ui/material_ui.dart';

class CustomValidator<T> extends FormField<T> {
  CustomValidator({
    required FormFieldValidator<T> super.validator,
    required Widget Function(FormFieldState<T> state) builder,
    super.key,
    super.initialValue,
  }) : super(
         autovalidateMode: AutovalidateMode.onUserInteraction,
         builder: (state) {
           return builder(state);
         },
       );
}
