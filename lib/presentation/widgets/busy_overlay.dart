import 'package:flutter/material.dart';
import 'package:sweat_lock/core/theme.dart';

class BusyOverlay extends StatelessWidget {
  final Widget? child;
  final String title;
  final bool show;
  final int height;
  final double opacity;

  const BusyOverlay({
    Key? key,
    this.child,
    this.title = 'Please wait...',
    this.show = false,
    this.height = 0,
    this.opacity = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child!,
        IgnorePointer(
          ignoring: !show,
          child: Opacity(
            opacity: show ? 1.0 : 0.0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              color: Theme.of(context).cardColor.withOpacity(opacity),
              //color: const Color.fromARGB(100, 0, 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).cardColor,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  // const Image(
                  //   image: AssetImage("assets/logo.png"),
                  //   width: 50,
                  // ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: height.toDouble()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
