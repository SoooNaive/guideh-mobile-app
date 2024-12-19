import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset('assets/images/guideh-logo.png')
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Image.asset(
                      'assets/images/insurance_broker.png',
                      height: screenSize.height - 300,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('Войти'),
                    onPressed: () => context.go('/start/login') ,
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    child: const Text('Зарегистрироваться'),
                    onPressed: () => context.go('/start/signup') ,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
