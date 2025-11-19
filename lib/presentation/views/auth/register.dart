import 'package:flutter/material.dart';
import 'package:sweat_lock/gen/assets.gen.dart';
import 'package:sweat_lock/presentation/widgets/form_field.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

import 'login.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isChecked = false;
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
                    shrinkWrap: true,
                    primary: true,
                    children: [
                      ///Logo and text
                      Column(
                        children: [
                          Image.asset(
                            Assets.icons.google.path,
                            width: MediaQuery.of(context).size.width - 150,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Unlock Your Potential",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 35),
                        ],
                      ),
                      //Email
                      CustomTextField(password: false, hint: "Email"),
                      const SizedBox(height: 15),

                      //Username
                      CustomTextField(password: false, hint: "Username"),
                      const SizedBox(height: 15),

                      //Password
                      CustomTextField(hint: "Password"),

                      //Agreement?
                      CheckboxListTile(
                        value: _isChecked,
                        onChanged: (value) {
                          setState(() {
                            _isChecked = value!;
                          });
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0.0,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          "I agree to the Terms of Use and Privacy Policy",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),

                      //Register Button
                      CustomButton(text: "Register"),

                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Text(
                                "OR",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      //Social buttons
                      SocialButton(
                        text: "Continue with Google",
                        icon: Image.asset(Assets.icons.google.path, width: 40),
                      ),
                      const SizedBox(height: 15),

                      SocialButton(
                        text: "Continue with Apple",
                        icon: Image.asset(Assets.icons.google.path, width: 40),
                      ),

                      //Already have an account
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginView(),
                                  ),
                                );
                              },
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //About
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "About | Terms of Use",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),

                      const SizedBox(height: 20),
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
