import 'package:chrono_list/presentation/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:chrono_list/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _selectedDay= DateTime.now();
  @override
  void initState(){
    waitSplash();
    super.initState();
    
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 50,height: 50,
          child: CircularProgressIndicator(
        strokeWidth: 6,
        color: Colors.blue, // or any color you prefer
      ),
        ),
      )
    );
  }
  waitSplash() async{
    await Future.delayed(Duration(seconds: 1));
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
  }
}