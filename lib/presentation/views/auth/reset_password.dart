import 'package:flutter/material.dart';
import 'package:sweat_lock/gen/assets.gen.dart';
import 'package:sweat_lock/presentation/views/auth/new_password.dart';
import 'package:sweat_lock/presentation/widgets/form_field.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class Reset extends StatefulWidget {
  const Reset({Key? key}) : super(key: key);

  @override
  _ResetState createState() => _ResetState();
}

class _ResetState extends State<Reset> {
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
                      //Header text
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
                              "Enter your username or email and we'll send you a link to get back into your account.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      //Email
                      CustomTextField(password: false, hint: "Email/Username"),

                      const SizedBox(height: 20),
                      //Reset Button
                      CustomButton(text: "Submit"),
                      const SizedBox(height: 20),

                      //Don't have an account
                      Container(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NewPassword()),
                            );
                          },
                          child: Text(
                            "Have Code?",
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
