import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import 'dart:io';

class SpinWheel extends StatefulWidget {
  const SpinWheel({Key? key}) : super(key: key);

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel> {
  final selected = BehaviorSubject<int>();
  int rewards = 0;

  List<int> items = [
    0, 10, 20, 50, 100, 200, 300
  ];
  String buttonText = "SPIN";
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  void _loadInterstitialAd(){
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-5951546517300147/3255581973',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded:(InterstitialAd ad){
            setState(() {
              _interstitialAd = ad;
              _isAdLoading = false;
            });
          },
          onAdFailedToLoad: (LoadAdError){
            print('Interstitial ad failed to load: ');
            setState(() {
              _isAdLoading=false;
            });
          },
        ),
    );
  }

  void _showInterstitialAd(){
    if(_interstitialAd == null){
      print('Warning: attemp to show interstitial before loaded !');
      return;
    }
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad){
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error){
        print('Ad failed to show: $error');
        ad.dispose();
        _loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  void initState(){
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    selected.close();
    super.dispose();
  }

  int clickCount =0;
  void _handleButtonClick() {
    setState(() {
      clickCount++;
      print("Click count = " + clickCount.toString());
      if (clickCount >= 3) {
        clickCount = 0;
        // Here you can place your ad display logic
        buttonText="WATCH ADD";
        if(!_isAdLoading && _interstitialAd != null){
          _showInterstitialAd();
          buttonText="SPIN";
        }
        print("Time to show an ad!");
        // ShowAd(); // Uncomment this and implement the function to show an ad
      }
      else{
        buttonText="SPIN";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Spin Your Luck"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 300,
              child: FortuneWheel(
                selected: selected.stream,
                animateFirst: false,
                items: [
                  for(int i = 0; i < items.length; i++)...<FortuneItem>{
                    FortuneItem(child: Text(items[i].toString())),
                  },
                ],
                onAnimationEnd: () {
                  setState(() {
                    rewards = items[selected.value];
                  });
                  print(rewards);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("You just won " + rewards.toString() + " Points!"),
                      backgroundColor: Colors.blueAccent,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(50),
                      elevation: 30,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 40,),
            GestureDetector(
              onTap: () {
                _handleButtonClick();
                setState(() {
                  selected.add(Fortune.randomInt(0, items.length));
                });
              },
              child: Container(
                height: 40,
                width: 120,
                color: Colors.deepPurpleAccent,
                  child: Center(
                    child: Text(buttonText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}