import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/format_date.dart';
import 'package:guideh/services/format_phone.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  // render
  @override
  Widget build(BuildContext context) {
    final signupFormKey = GlobalKey<FormState>();

    TextEditingController phone = TextEditingController();
    TextEditingController email = TextEditingController();
    TextEditingController lastname = TextEditingController();
    TextEditingController firstname = TextEditingController();
    TextEditingController middlename = TextEditingController();
    TextEditingController birthdate = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Form(
            key: signupFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: lastname,
                  decoration: const InputDecoration(labelText: "Фамилия"),
                  keyboardType: TextInputType.name,
                  validator: (value) => value!.isEmpty ? 'Введите фамилию' : null,
                ),
                TextFormField(
                  controller: firstname,
                  decoration: const InputDecoration(labelText: "Имя"),
                  keyboardType: TextInputType.name,
                  validator: (value) => value!.isEmpty ? 'Введите имя' : null,
                ),
                TextFormField(
                  controller: middlename,
                  decoration: const InputDecoration(labelText: "Отчество"),
                  keyboardType: TextInputType.name,
                ),
                TextFormField(
                  controller: birthdate,
                  decoration: const InputDecoration(
                    labelText: 'Дата рождения',
                    counterText: '',
                    errorMaxLines: 2
                  ),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [DateTextFormatter()],
                  maxLength: 10,
                  validator: (value) {
                    return (value?.length != 10) ? 'Введите дату рождения в формате ДД.ММ.ГГГГ' : null;
                  },
                ),
                TextFormField(
                  controller: phone,
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
                  controller: email,
                  decoration: const InputDecoration(labelText: "E`mail"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Введите адрес электронной почты' : null,
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  child: const Text('Зарегистрироваться'),
                  onPressed: () async {
                    if (signupFormKey.currentState!.validate()) {
                      var signupParams = SignupParams(
                        lastname: lastname.text,
                        firstname: firstname.text,
                        middlename: middlename.text,
                        birthdate: birthdate.text,
                        phone: phone.text,
                        email: email.text,
                      );
                      var result = await signup(signupParams, context);
                      if (result == 'OK') {
                        if (context.mounted) {
                          context.goNamed('login');
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Нажимая на "Зарегистрироваться", вы соглашаетесь с условиями ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: 'политики конфиденциальности',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer() ..onTap = () => goUrl('https://guidehins.ru/privacy-policy/')
                      ),
                      const TextSpan(
                        text: ' и ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: 'пользовательского соглашения',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer() ..onTap = () => goUrl('https://guidehins.ru/politika-v-otnoshenii-obrabotki-personalnyx-dannyx/')
                      ),
                      const TextSpan(
                        text: '.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignupParams {
  SignupParams({
    required this.lastname,
    required this.firstname,
    required this.middlename,
    required this.birthdate,
    required this.phone,
    required this.email,
  });

  Map<String, String> toMap() {
    return {
      'lastname': lastname,
      'firstname': firstname,
      'middlename': middlename,
      'birthdate': birthdate,
      'phone': phone,
      'email': email,
    };
  }

  String lastname;
  String firstname;
  String middlename;
  String birthdate;
  String phone;
  String email;
}

Future<dynamic> signup(SignupParams signupParams, BuildContext context) async {

  final response = await Http.mobApp(ApiParams('MobApp', 'MP_signup', signupParams.toMap()));
  if (response['Error'] == 0) {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('phone', signupParams.phone);
    prefs.setString('password', response['password']);
    prefs.setString('token', response['token']);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['Message']),
        ),
      );
    }

    return 'OK';

  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['Message']),
        ),
      );
    }
  }

}