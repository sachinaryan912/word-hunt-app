import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Where a rewarded ad is offered. Each has its own AdMob ad unit and its
/// own preloaded RewardedAd slot, so claiming one doesn't consume or
/// interfere with the other's cached ad.
enum RewardedPlacement { dailyGift, matchBonus }

/// Each placement below is its own ad unit in AdMob (rather than one shared
/// unit) so per-placement performance is visible in AdMob's reporting.
class AdsService {
  // Banner — one per placement.
  static const String homeBannerAdUnitId = 'ca-app-pub-7270999860067391/9836033507';
  static const String soloBannerAdUnitId = 'ca-app-pub-7270999860067391/7471548442';
  static const String multiplayerBannerAdUnitId = 'ca-app-pub-7270999860067391/5758127047';

  // Interstitial — single placement (solo "Return Home").
  static const String interstitialAdUnitId = 'ca-app-pub-7270999860067391/1818882039';

  // Rewarded — one per placement.
  static const Map<RewardedPlacement, String> _rewardedAdUnitIds = {
    RewardedPlacement.dailyGift: 'ca-app-pub-7270999860067391/9378642004',
    RewardedPlacement.matchBonus: 'ca-app-pub-7270999860067391/9034087726',
  };

  InterstitialAd? _interstitial;
  final Map<RewardedPlacement, RewardedAd?> _rewarded = {
    RewardedPlacement.dailyGift: null,
    RewardedPlacement.matchBonus: null,
  };

  static Future<void> initialize() => MobileAds.instance.initialize();

  void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void showInterstitialIfReady({VoidCallback? onDismissed}) {
    final ad = _interstitial;
    if (ad == null) {
      onDismissed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _interstitial = null;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _interstitial = null;
        onDismissed?.call();
      },
    );
    ad.show();
  }

  void preloadRewarded(RewardedPlacement placement) {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitIds[placement]!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded[placement] = ad,
        onAdFailedToLoad: (_) => _rewarded[placement] = null,
      ),
    );
  }

  bool isRewardedReady(RewardedPlacement placement) => _rewarded[placement] != null;

  void showRewarded(
    RewardedPlacement placement, {
    required VoidCallback onEarnedReward,
    VoidCallback? onDismissed,
  }) {
    final ad = _rewarded[placement];
    if (ad == null) {
      onDismissed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewarded[placement] = null;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewarded[placement] = null;
        onDismissed?.call();
      },
    );
    ad.show(onUserEarnedReward: (_, reward) => onEarnedReward());
  }
}
