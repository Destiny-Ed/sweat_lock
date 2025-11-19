import 'package:flutter/material.dart';
import 'package:sweat_lock/gen/assets.gen.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/widgets/form_field.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class NewPassword extends StatefulWidget {
  const NewPassword({super.key});

  @override
  _NewPasswordState createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                height: MediaQuery.of(context).size.height - 40,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ListView(
                    primary: false,
                    shrinkWrap: true,
                    children: [
                      //Header Text
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Image.asset(
                              Assets.icons.google.path,
                              width: MediaQuery.of(context).size.width - 150,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Reset Password",
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Enter the code you received and a new password",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      //Code
                      CustomTextField(password: false, hint: "Code"),
                      const SizedBox(height: 20),

                      //Password
                      CustomTextField(hint: "Password"),

                      const SizedBox(height: 20),

                      //Submit Button
                      CustomButton(text: "Submit"),

                      //Login with new account account
                      Container(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginView()),
                            );
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
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
