import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/format_phone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoverpassScreen extends StatefulWidget {
  final String phone;
  const RecoverpassScreen({super.key, required this.phone});

  @override
  State<RecoverpassScreen> createState() => _RecoverpassScreenState();
}

class _RecoverpassScreenState extends State<RecoverpassScreen> {
  final recoverPasswordFormKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final TextEditingController phoneController = TextEditingController(text: widget.phone);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Восстановить пароль'),
      ),
      body: Center(
        child: isLoading
          ? const CircularProgressIndicator()
          : Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 100),
          child: Form(
            key: recoverPasswordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    prefixText: '+7',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [phoneInputFormatter],
                  validator: (value) {
                    if (value!.isEmpty) return 'Введите номер телефона';
                    if (value.length < 16) return 'Неверный формат номера';
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Отправить новый пароль в СМС'),
                  onPressed: () async {
                    if (recoverPasswordFormKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      var result = await Auth.passRecovery(phoneController.text);
                      if (result == 'OK') {
                        SharedPreferences preferences = await SharedPreferences.getInstance();
                        preferences.setString('phone', phoneController.text);
                        preferences.remove('password');
                        if (context.mounted) {
                          context.goNamed(
                            'login',
                            queryParameters: {
                              'isPasswordRecovered': 'true'
                            }
                          );
                          // снэкбар "введите пароль из смс"
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Введите пароль из СМС')),
                          );
                        }
                      }
                      else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.toString()),
                            ),
                          );
                        }
                        setState(() => isLoading = false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
