import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdHelper {
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/1033173712";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/4411468910";
    } else {
      throw UnsupportedError("Unsupported platform");
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

  List<Map<String, dynamic>> items = [];
  String buttonText = "SPIN";
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
    fetchRewards();
  }

  Future<void> fetchRewards() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('rewards').get();
    setState(() {
      items = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
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
      ),
    );
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
        setState(() {
          buttonText = "SPIN";
        });
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
        setState(() {
          buttonText = 'SPIN';
        });
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

  int clickCount = 0;

  void _handleButtonClick() {
    setState(() {
      print('Click Count ' + clickCount.toString());
      if (clickCount == 3) {
        clickCount = 0;
        buttonText = "WATCH AD";
      } else {
        buttonText = "SPIN";
      }
    });

    if (buttonText == "WATCH AD") {
      if (_interstitialAd != null) {
        _showInterstitialAd();
      } else {
        print("No ad loaded yet, retrying...");
        _createInterstitialAd();
      }
    } else {
      setState(() {
        selected.add(Fortune.randomInt(0, items.length));
      });
      clickCount++;
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
            if (items.isEmpty) CircularProgressIndicator(),
            if (items.isNotEmpty)
              SizedBox(
                height: 300,
                child: FortuneWheel(
                  selected: selected.stream,
                  animateFirst: false,
                  items: [
                    for (int i = 0; i < items.length; i++)
                      FortuneItem(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(items[i]['name'].toString()),
                            if (items[i]['image'] != null)
                              Image.network(
                                items[i]['image'].toString(),
                                height: 50,
                              ),
                          ],
                        ),
                      ),
                  ],
                  onAnimationEnd: () {
                    setState(() {
                      rewards = items[selected.value]['value'];
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
            SizedBox(height: 40),
            GestureDetector(
              onTap: _handleButtonClick,
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
