import 'package:flutter/material.dart';
import 'package:spinwheel/spinthewheel.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyDrwVWSo7nPANVN3XuJfGbf7-vJ9fAo2-o",
        appId: "1:286859342101:android:1227845cb567ef1c3b391c",
        messagingSenderId: "286859342101",
        projectId: "spinwheel-ee5cd")
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SpinWheel(),
        debugShowCheckedModeBanner: false
    );
  }
}
