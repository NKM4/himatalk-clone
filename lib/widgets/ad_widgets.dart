import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

/// 広告ウィジェット
/// Google Mobile Ads を使用

// テスト広告ID（本番では実際のIDに置き換え）
class AdIds {
  // Android テスト ID
  static const String androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // iOS テスト ID
  static const String iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static String get bannerId => defaultTargetPlatform == TargetPlatform.iOS
      ? iosBanner
      : androidBanner;

  static String get interstitialId => defaultTargetPlatform == TargetPlatform.iOS
      ? iosInterstitial
      : androidInterstitial;

  static String get rewardedId => defaultTargetPlatform == TargetPlatform.iOS
      ? iosRewarded
      : androidRewarded;
}

/// バナー広告ウィジェット
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return; // Webでは広告非対応

    _bannerAd = BannerAd(
      adUnitId: AdIds.bannerId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('バナー広告ロード完了');
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('バナー広告エラー: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// インタースティシャル広告サービス
class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;

  /// 広告をロード
  static void load() {
    if (kIsWeb) return;

    InterstitialAd.load(
      adUnitId: AdIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('インタースティシャル広告ロード完了');
          _interstitialAd = ad;
          _isLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isLoaded = false;
              load(); // 次の広告をロード
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isLoaded = false;
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('インタースティシャル広告エラー: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  /// 広告を表示
  static Future<void> show() async {
    if (!_isLoaded || _interstitialAd == null) {
      debugPrint('インタースティシャル広告未ロード');
      return;
    }

    await _interstitialAd!.show();
    _interstitialAd = null;
  }

  /// 広告がロード済みか
  static bool get isLoaded => _isLoaded;
}

/// リワード広告サービス
class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isLoaded = false;

  /// 広告をロード
  static void load() {
    if (kIsWeb) return;

    RewardedAd.load(
      adUnitId: AdIds.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('リワード広告ロード完了');
          _rewardedAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('リワード広告エラー: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  /// 広告を表示
  static Future<bool> show() async {
    if (!_isLoaded || _rewardedAd == null) {
      debugPrint('リワード広告未ロード');
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isLoaded = false;
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isLoaded = false;
        load();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('リワード獲得: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );

    _rewardedAd = null;
    return rewarded;
  }

  /// 広告がロード済みか
  static bool get isLoaded => _isLoaded;
}
