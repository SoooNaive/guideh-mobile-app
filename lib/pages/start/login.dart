import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/format_phone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final String? isPasswordRecovered;
  const LoginScreen({super.key, this.isPasswordRecovered});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginFormKey = GlobalKey<FormState>();

  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool isLoading = false;

  getFormData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? phone = preferences.getString('phone');
    _phone.text = phone != null
      ? phone.contains('+7') ? phone.replaceAll('+7', '') : phone
      : '';
  }

  @override
  void initState() {
    getFormData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторизация'),
      ),
      body: Center(
        child: isLoading
          ? const CircularProgressIndicator()
          : Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 100),
          child: Form(
            key: loginFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _phone,
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
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  keyboardType: TextInputType.visiblePassword,
                  validator: (value) => value!.isEmpty ? 'Введите пароль' : null,
                  // если пришли с восстановления пароля - фокус
                  autofocus: (widget.isPasswordRecovered ?? '') != '',
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.goNamed(
                        'recoverpass',
                        queryParameters: {
                          'phone': _phone.text
                        }
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Восстановить пароль',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (loginFormKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            SharedPreferences preferences = await SharedPreferences.getInstance();
                            await preferences.setString('phone', _phone.text);
                            // ignore: use_build_context_synchronously
                            var result = await Auth.login(_phone.text, _password.text, context);
                            if (result == null) return;
                            if (result == 'OK') {
                              if (context.mounted) {
                                context.goNamed(
                                  'polis_list',
                                  queryParameters: {
                                    'updateListPolis': 'true',
                                  },
                                );
                              }
                            } else {
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
                        child: const Text('Войти'),
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 15),
                // const Text(
                //   '— или —',
                //   style: TextStyle(color: Colors.black38),
                // ),
                // const SizedBox(height: 15),
                // ElevatedButton(
                //   onPressed: () => goUrl(esiaLoginUrl),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.white,
                //   ),
                //   child: Padding(
                //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         Image.asset(
                //           'assets/images/gosuslugi_logo.png',
                //           height: 50,
                //         ),
                //         const SizedBox(width: 10),
                //         const Flexible(
                //           child: Text(
                //             'Войти через ГОСУСЛУГИ',
                //             style: TextStyle(color: Colors.black45),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class User {
  final int index;
  final String about;
  final String name;
  final String email;
  final String picture;

  User(this.index, this.about, this.name, this.email, this.picture);
}
