import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';


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
  Map<String, dynamic> rewards= {};
  List<Map<String, dynamic>> items = [];
  String buttonText = "SPIN";
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  final _controller = ConfettiController(duration: Duration(seconds: 3));
  final player1 = AudioPlayer();
  final player2 = AudioPlayer();
  final player3 = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
    _fetchRewards();
    player1.setSourceUrl('assets/sounds/wheel.mp3');
    player2.setSourceUrl('assets/sounds/winning.mp3');
    player3.setSourceUrl('assets/sounds/winning.mp3');
  }

  Future<void> _fetchRewards() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Rewards').get();
      List<Map<String, dynamic>> fetchedItems = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "name": data['name'] ?? "No Name",
          "value": data['value'] ?? 0,
          "image": data['image'] ?? "https://example.com/default_image.png",
          "coupon": data['coupon'] ?? "No Coupon" // Change key to coupon
        };
      }).toList();

      if (fetchedItems.isEmpty) {
        // Provide some default rewards if none are found in Firestore
        fetchedItems = [
          {"name": "Better Luck next time", "value": 0, "image": "https://example.com/default_image.png", "coupon": "No Coupon"},
          {"name": "10 Points", "value": 10, "image": "https://example.com/10_points.png", "coupon": "COUPON10"},
          {"name": "20 Points", "value": 20, "image": "https://example.com/20_points.png", "coupon": "COUPON20"},
        ];
      }

      setState(() {
        items = fetchedItems;
      });
    } catch (e) {
      print('Failed to fetch rewards: $e');
      // Provide some default rewards in case of an error
      setState(() {
        items = [
          {"name": "Better Luck next time", "value": 0, "image": "https://example.com/default_image.png", "coupon": "No Coupon"},
          {"name": "10 Points", "value": 10, "image": "https://example.com/10_points.png", "coupon": "COUPON10"},
          {"name": "20 Points", "value": 20, "image": "https://example.com/20_points.png", "coupon": "COUPON20"},
        ];
      });
    }
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
    _controller.dispose();
    player1.dispose();
    player2.dispose();
    player3.dispose();
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
        player1.play(AssetSource('sounds/wheel.mp3'));
        selected.add(Fortune.randomInt(0, items.length));
      });
      clickCount++;
    }
  }
  List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  Color _getColor(int index) {
    return _colors[index % _colors.length];
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
        backgroundColor:Colors.black38,
        appBar: AppBar(
          title: Text("Spin Your Luck",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white12,
        ),

        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (items.isEmpty)
                CircularProgressIndicator()
              else if (items.length > 1)

                SizedBox(
                  height: 350,
                  child: FortuneWheel(
                    selected: selected.stream,
                    animateFirst: false,
                    items: [
                      for (int i = 0; i < items.length; i++) ...<FortuneItem>{
                        FortuneItem(
                          style: FortuneItemStyle(
                            color: _getColor(i),
                            borderColor: Colors.black,
                            borderWidth: 3,
                          ),
                          child: Text(items[i]['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      },
                    ],
                    onAnimationEnd: () {
                      player1.pause();
                      setState(() {
                        rewards = items[selected.value];
                      });
                      print(rewards);
                      if (rewards['value'] == 0 || rewards['name'].toLowerCase().contains('better luck next time')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Better luck next time!"),
                              backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        _controller.play();
                        player2.play(AssetSource('sounds/winning.mp3'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("You just won ${rewards['name']} worth of ${rewards['value']}!"),
                              backgroundColor: Colors.blueAccent,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(50),
                              elevation: 30,
                          ),
                        );
                      }
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: rewards['coupon'] ?? "No Coupon"));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Coupon code copied to clipboard!'),
                                          backgroundColor: Colors.blueAccent,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(50),
                                          elevation: 500,
                                          duration: Duration(milliseconds: 1000),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      rewards['coupon'] ?? "No Coupon",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  rewards['name'] ?? "No Name",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Close"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    indicators: <FortuneIndicator>[
                      FortuneIndicator(
                        alignment: Alignment.center,
                        child: RoundIndicator(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 40),
              Text(
                "Play now to reveal your prize",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: _handleButtonClick,
                child: Container(
                  height: 40,
                  width: 200, // Make the button slimmer
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
        ConfettiWidget(
           confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 500,
        ),
    ],
    );
  }
}

class RoundIndicator extends StatelessWidget {
  final Color color;

  const RoundIndicator({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white12,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
          child: Text(
            '▲',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
      ),
    );
  }
}