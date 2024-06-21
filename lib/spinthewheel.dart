import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdHelper{
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/1033173712";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/4411468910";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}

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
  int _numInterstitialLoadAttempts =0;
  int maxFailedLoadAttempts=3;
  // void _loadInterstitialAd(){
  //   InterstitialAd.load(
  //       adUnitId: 'ca-app-pub-5951546517300147/3255581973',
  //       request: AdRequest(),
  //       adLoadCallback: InterstitialAdLoadCallback(
  //         onAdLoaded:(InterstitialAd ad){
  //           setState(() {
  //             _interstitialAd = ad;
  //             _isAdLoading = false;
  //           });
  //         },
  //         onAdFailedToLoad: (LoadAdError){
  //           print('Interstitial ad failed to load: ');
  //           setState(() {
  //             _isAdLoading=false;
  //           });
  //         },
  //       ),
  //   );
  // }
  //
  // void _showInterstitialAd(){
  //   if(_interstitialAd == null){
  //     print('Warning: attemp to show interstitial before loaded !');
  //     return;
  //   }
  //   _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
  //     onAdDismissedFullScreenContent: (InterstitialAd ad){
  //       ad.dispose();
  //       _loadInterstitialAd();
  //     },
  //     onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error){
  //       print('Ad failed to show: $error');
  //       ad.dispose();
  //       _loadInterstitialAd();
  //     },
  //   );
  //   _interstitialAd!.show();
  //   _interstitialAd = null;
  // }

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }
  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }
  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
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
      print('Click Count'+ clickCount.toString());
      if (clickCount >= 3) {
        clickCount = 0;
        buttonText = "WATCH AD";
      } else {
        buttonText = "SPIN";
      }
    });

    if (buttonText == "WATCH AD") {
      if (_interstitialAd != null) {
        _showInterstitialAd();
        buttonText = "SPIN";  // Consider moving this inside _showInterstitialAd as a final step
      } else {
        print("No ad loaded yet, retrying...");
        _createInterstitialAd(); // Optionally trigger another load if not already loading
      }
    } else {
      setState(() {
        selected.add(Fortune.randomInt(0, items.length));
      });
    }
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