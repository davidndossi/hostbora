import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/registration_controller.dart';

class RegistrationView extends BaseView<RegistrationController> {
  RegistrationView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height > 800
            ? MediaQuery.of(context).size.height - AppValues.size_100
            : 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children:[
            const SizedBox(height: 20),
            Image.asset('images/paa_yangu_logo.png', width: 100),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: Text(
                appLocalization.registerYourAccount,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                )
              )
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: Form(
                key: controller.registerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:[
                    TextFormField(
                      autofocus: true,
                      controller: controller.nameController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: appLocalization.name,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppColors.colorPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: controller.nameValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      autofocus: true,
                      controller: controller.msisdnController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: appLocalization.msisdn,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppColors.colorPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: controller.msisdnValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email (optional)',
                        hintText: 'e.g. you@example.com',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppColors.colorPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: controller.emailValidator,
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text('Gender'),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => RadioGroup(
                              groupValue: controller.selectedGender.value,
                              onChanged: (String? value) {
                                controller.selectedGender(value);
                              },
                              child: RadioListTile<String>(
                                title: const Text('Male'),
                                value: 'male',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(
                            () => RadioGroup(
                              groupValue: controller.selectedGender.value,
                              onChanged: (String? value) {
                                controller.selectedGender(value);
                              },
                              child: RadioListTile<String>(
                                title: const Text('Female'),
                                value: 'female',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: appLocalization.password,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppColors.colorPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      obscureText: true,
                      validator: controller.passwordValidator,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        width: 316,
                        height: 48,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isLoading.isTrue ? null : controller.register,
                            style: ButtonStyle(
                              fixedSize: WidgetStateProperty.all(
                                  const Size(AppValues.size_200, AppValues.size_48))
                            ),
                            child: controller.isLoading.isTrue
                                ?
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              )
                            )
                                :
                            Text(
                              appLocalization.register,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: InkWell(
                  onTap: () => Get.offAllNamed(Routes.AUTH),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      appLocalization.login,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.colorPrimary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.colorPrimary,
                      ),
                    )
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}