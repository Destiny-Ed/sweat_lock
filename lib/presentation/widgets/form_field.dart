import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  // final TextEditingController _controller;
  bool obscure;
  final String hint;
  final bool password;
  CustomTextField(
  // this._controller,
  {super.key, this.password = true, this.obscure = false, this.hint = ''});

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  Icon? visibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(),
      ),
      child: TextFormField(
        style: Theme.of(context).textTheme.titleMedium,
        // controller: widget._controller,
        obscureText: widget.obscure,

        decoration: InputDecoration(
          border: InputBorder.none,
          suffixIcon: widget.password == true
              ? GestureDetector(
                  key: widget.key,
                  onTap: () {
                    //Show and hide password
                    if (widget.obscure == true) {
                      setState(() {
                        widget.obscure = false;
                        visibility = Icon(
                          Icons.visibility_off,
                          color: Theme.of(context).primaryColor,
                        );
                      });
                    } else {
                      setState(() {
                        widget.obscure = true;
                        visibility = Icon(
                          Icons.visibility,
                          color: Theme.of(context).primaryColor,
                        );
                      });
                    }
                  },
                  child:
                      visibility ??
                      Icon(
                        Icons.visibility,
                        color: Theme.of(context).primaryColor,
                      ),
                )
              : const Text(""),

          hintText: widget.hint,
        ),
      ),
    );
  }
}
