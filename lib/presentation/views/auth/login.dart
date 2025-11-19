import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/gen/assets.gen.dart';
import 'package:sweat_lock/presentation/views/auth/register.dart';
import 'package:sweat_lock/presentation/views/auth/reset_password.dart';
import 'package:sweat_lock/presentation/views/onboarding/onboarding.dart';
import 'package:sweat_lock/presentation/widgets/form_field.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  LoginViewState createState() => LoginViewState();
}

class LoginViewState extends State<LoginView> {
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
                      //Logo and text
                      Column(
                        children: [
                          Image.asset(
                            Assets.icons.google.path,
                            width: MediaQuery.of(context).size.width - 150,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Welcome Back To $appName",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Ready to earn your screen time?",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 35),

                          CustomTextField(password: false, hint: "Email"),

                          const SizedBox(height: 15),

                          //Password
                          CustomTextField(hint: "Password"),

                          //Forgot password?
                          Container(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => Reset()),
                                );
                              },
                              child: Text(
                                "Forgot Password",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          //Login Button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Onboarding(),
                                ),
                              );
                            },
                            child: CustomButton(text: "Login"),
                          ),

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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          //Social buttons
                          SocialButton(
                            text: "Continue with Google",
                            icon: Image.asset(
                              Assets.icons.google.path,
                              width: 40,
                            ),
                          ),
                          const SizedBox(height: 15),

                          SocialButton(
                            text: "Continue with Apple",
                            icon: Image.asset(
                              Assets.icons.google.path,
                              width: 40,
                            ),
                          ),
                        ],
                      ),

                      //Don't have an account
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => Register()),
                                );
                              },
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
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
