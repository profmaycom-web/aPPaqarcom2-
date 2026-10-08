import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/phone_field.dart';
import 'package:ebroker/utils/validator.dart';
import 'package:material_ui/material_ui.dart';

class EmailRegistrationForm extends StatefulWidget {
  const EmailRegistrationForm({required this.email, super.key});

  final String email;

  @override
  State<EmailRegistrationForm> createState() => _EmailRegistrationFormState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SendOtpCubit()),
          BlocProvider(create: (context) => VerifyOtpCubit()),
        ],
        child: EmailRegistrationForm(
          email: arguments['email']?.toString() ?? '',
        ),
      ),
    );
  }
}

class _EmailRegistrationFormState extends State<EmailRegistrationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Timer? timer;
  final ValueNotifier<int> otpResendTime = ValueNotifier<int>(
    AppConfig.otpResendSecond,
  );

  String countryCode = '';
  bool isFirstPasswordVisible = true;
  bool isSecondPasswordVisible = true;

  @override
  void initState() {
    super.initState();
    unawaited(startTimer());
    emailController.text = widget.email;
  }

  @override
  void dispose() {
    timer?.cancel();
    if (mounted) otpResendTime.dispose();
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendOtpCubit, SendOtpState>(
      listener: _handleOtpState,
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: 'registerEmail'.translate(context),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            child: _buildEmailRegistrationForm(context),
          ),
        ),
      ),
    );
  }

  Future<void> _handleOtpState(BuildContext context, SendOtpState state) async {
    if (state is SendOtpInProgress) {
      unawaited(Widgets.showLoader(context));
    } else if (state is SendOtpFailure) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        state.errorMessage,
        type: .error,
      );
    } else if (state is SendOtpSuccess) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        'optsentsuccessflly',
        type: .success,
      );
      await Navigator.pushReplacementNamed(
        context,
        Routes.otpScreen,
        arguments: {
          'isDeleteAccount': false,
          'phoneNumber': mobileController.text.isNotEmpty
              ? mobileController.text.trim()
              : '',
          'email': emailController.text.trim(),
          'otpVerificationId': state.verificationId,
          'countryCode': countryCode,
          'otpIs': 'emailRegistration', // Flag for email registration
          'isEmailSelected': true,
          // Pass registration data to OTP screen
          'name': nameController.text.trim(),
          'password': passwordController.text.trim(),
          'rePassword': confirmPasswordController.text.trim(),
        },
      );
    }
  }

  Widget _buildEmailRegistrationForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              context,
              title: 'fullName'.translate(context),
              controller: nameController,
              validator: CustomTextFieldValidator.nullCheck,
              isPhoneNumber: false,
              hintText: 'fullName'.translate(context),
            ),
            _buildTextField(
              context,
              title: 'email'.translate(context),
              hintText: 'example@email.com',
              validator: CustomTextFieldValidator.email,
              controller: emailController,
              isPhoneNumber: false,
            ),
            _buildTextField(
              context,
              title: 'phoneNumber'.translate(context),
              hintText: '0000000000',
              validator: CustomTextFieldValidator.phoneNumber,
              controller: mobileController,
              keyboard: TextInputType.phone,
              isPhoneNumber: true,
            ),
            _buildPasswordField(
              context,
              title: 'password'.translate(context),
              hintText: 'password'.translate(context),
              validator: (value) => Validator.validatePassword(
                context,
                value?.toString() ?? '',
                secondFieldValue: passwordController.text,
              ),
              controller: passwordController,
              isPasswordVisible: isFirstPasswordVisible,
              onToggleVisibility: () {
                setState(
                  () => isFirstPasswordVisible = !isFirstPasswordVisible,
                );
              },
            ),
            _buildPasswordField(
              context,
              title: 'confirmPassword'.translate(context),
              hintText: 'confirmPassword'.translate(context),
              controller: confirmPasswordController,
              validator: (value) => Validator.validatePassword(
                context,
                value?.toString() ?? '',
                secondFieldValue: passwordController.text,
              ),
              isPasswordVisible: isSecondPasswordVisible,
              onToggleVisibility: () {
                setState(
                  () => isSecondPasswordVisible = !isSecondPasswordVisible,
                );
              },
            ),
            SizedBox(height: 16.rh(context)),
            UiUtils.buildButton(
              context,
              buttonTitle: 'register'.translate(context),
              onPressed: _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final checkMobile = mobileController.text.isNotEmpty;
    if (_formKey.currentState!.validate()) {
      await context.read<SendOtpCubit>().sendEmailOTP(
        email: emailController.text,
        name: nameController.text,
        phoneNumber: checkMobile ? mobileController.text : '',
        countryCode: countryCode,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );
    } else {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillAllFields',
        type: .error,
      );
    }
  }

  Widget _buildTextField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required bool isPhoneNumber,
    required String hintText,
    List<TextInputFormatter>? formaters,
    TextInputType? keyboard,
    CustomTextFieldValidator? validator,
    bool? readOnly,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(height: 10.rh(context)),
        Row(
          children: [
            CustomText(title.translate(context)),
            SizedBox(width: 3.rw(context)),
            if (!isPhoneNumber) HelperUtils.requiredSymbol(context),
          ],
        ),
        SizedBox(height: 10.rh(context)),
        if (isPhoneNumber)
          PhoneField(
            controller: controller,
            hintText: hintText,
            enabled: readOnly != true,
            onCountryChanged: (value) {
              setState(() {
                countryCode = value;
              });
            },
          )
        else
          CustomTextFormField(
            hintText: hintText,
            textDirection: textDirection,
            controller: controller,
            keyboard: keyboard,
            isReadOnly: readOnly,
            validator: validator,
            formaters: formaters,
            fillColor: context.color.textLightColor.withValues(alpha: 00.01),
          ),
      ],
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String hintText,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    List<TextInputFormatter>? formaters,
    TextInputType? keyboard,
    Widget? prefix,
    FormFieldValidator<dynamic>? validator,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(height: 10.rh(context)),
        Row(
          children: [
            CustomText(title.translate(context)),
            SizedBox(width: 3.rw(context)),
            HelperUtils.requiredSymbol(context),
          ],
        ),
        SizedBox(height: 10.rh(context)),
        TextFormField(
          textDirection: textDirection,
          controller: controller,
          obscureText: isPasswordVisible,
          inputFormatters: formaters,
          keyboardAppearance: .light,
          style: TextStyle(
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
          validator: validator,
          keyboardType: keyboard,
          decoration: InputDecoration(
            prefix: prefix,
            hintText: hintText,
            suffixIcon: GestureDetector(
              onTap: onToggleVisibility,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomImage(
                  imageUrl: isPasswordVisible
                      ? AppIcons.eye
                      : AppIcons.eyeSlash,
                  color: context.color.textColorDark.withValues(alpha: 0.5),
                  width: 24.rw(context),
                  height: 24.rh(context),
                ),
              ),
            ),
            hintStyle: TextStyle(
              color: context.color.textColorDark.withValues(alpha: 0.7),
              fontSize: context.font.md,
            ),
            filled: true,
            fillColor: context.color.primaryColor,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: context.color.tertiaryColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: context.color.borderColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: context.color.borderColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget resendOtpTimerWidget() {
    return ValueListenableBuilder(
      valueListenable: otpResendTime,
      builder: (context, value, _) {
        if (!(timer?.isActive ?? false)) {
          return const SizedBox.shrink();
        }

        String formatSecondsToMinutes(int seconds) {
          final minutes = seconds ~/ 60;
          final remainingSeconds = seconds % 60;
          return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
        }

        final textColor = Theme.of(context).colorScheme.textColorDark;
        final tertiaryColor = Theme.of(context).colorScheme.tertiaryColor;

        return SizedBox(
          height: 70,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                text: 'resendMessage'.translate(context),
                style: TextStyle(
                  color: textColor,
                  letterSpacing: 0.5,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: formatSecondsToMinutes(value),
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: .w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'resendMessageDuration'.translate(context),
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: .w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> resendOTP() async {
    await context.read<SendOtpCubit>().sendEmailOTP(
      email: emailController.text.trim(),
      name: nameController.text.trim(),
      phoneNumber: mobileController.text.trim(),
      countryCode: countryCode,
      password: passwordController.text.trim(),
      confirmPassword: confirmPasswordController.text.trim(),
    );
  }

  Future<void> startTimer() async {
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (otpResendTime.value == 0) {
          timer.cancel();
          otpResendTime.value = AppConfig.otpResendSecond;
          setState(() {});
        } else if (mounted) {
          otpResendTime.value--;
        }
      },
    );
  }
}
