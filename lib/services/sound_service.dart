import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays the game's background music and one-shot sound effects (word
/// found, etc). Background music is started once when the app launches and
/// keeps playing across every screen; it's muted independently via the
/// "Background Music" toggle in Settings, separate from "Sound Effects".
/// It also auto-pauses whenever the app is backgrounded and resumes when
/// it comes back to the foreground (see [didChangeAppLifecycleState]).
///
/// All music transport calls (play/pause/resume/stop) are chained onto
/// [_musicOpChain] so they never overlap on the native side — issuing two
/// of these back to back (e.g. one screen's dispose racing another
/// screen's initState during a page transition) previously crashed the
/// Android MediaPlayer with a MEDIA_ERROR_UNKNOWN(-38) invalid-state error.
class SoundService with WidgetsBindingObserver {
  static const _musicAsset = 'musics/word_hunting_game_background_music.mp3';
  static const _wordFoundAsset = 'musics/win_sound.mp3';

  final AudioPlayer _musicPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _effectPlayer = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency)
    ..setReleaseMode(ReleaseMode.stop);

  bool _musicEnabled = true;
  bool _effectsEnabled = true;
  bool _hapticsEnabled = true;
  bool _musicStarted = false;
  bool _pausedForBackground = false;
  bool _effectSourceReady = false;
  Future<void> _musicOpChain = Future.value();
  late final Future<void> _prefsLoaded;

  SoundService() {
    _prefsLoaded = _loadPrefs();
    // A one-shot effect must not request exclusive audio focus — by default
    // audioplayers does, and on Android that silently pauses any other
    // player in the app (including our own looping music) the instant a
    // sound effect plays. contentType/usageType are deliberately left at
    // their music/media defaults (matching _musicPlayer) — routing this
    // through AndroidContentType.sonification instead puts it on a separate
    // audio-attributes stream that's commonly muted independently of media
    // volume (silent mode, Do Not Disturb, notification volume), which was
    // why the sound stayed silent even while background music kept playing.
    _effectPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ));
    _preloadEffect();
    WidgetsBinding.instance.addObserver(this);
  }

  /// PlayerMode.lowLatency plays through Android's SoundPool, which decodes
  /// the asset asynchronously the first time it's loaded. Calling
  /// play(AssetSource(...)) fresh on every trigger re-issues that load each
  /// time, and a play that lands before the decode finishes is silently
  /// dropped — which is why the win sound could fail to play. Loading the
  /// source once up front and just seeking+resuming it on each trigger
  /// avoids re-triggering that load path.
  Future<void> _preloadEffect() async {
    try {
      await _effectPlayer.setSourceAsset(_wordFoundAsset);
      await _effectPlayer.setVolume(0.9);
      _effectSourceReady = true;
    } catch (_) {
      _effectSourceReady = false;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool('pref_music') ?? true;
    _effectsEnabled = prefs.getBool('pref_sound') ?? true;
    _hapticsEnabled = prefs.getBool('pref_haptics') ?? true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_musicStarted && _musicEnabled) {
        _pausedForBackground = true;
        pauseBackgroundMusic();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedForBackground) {
        _pausedForBackground = false;
        resumeBackgroundMusic();
      }
    }
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (enabled) {
      if (_musicStarted) {
        resumeBackgroundMusic();
      } else {
        playBackgroundMusic();
      }
    } else {
      pauseBackgroundMusic();
    }
  }

  void setSoundEnabled(bool enabled) {
    _effectsEnabled = enabled;
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  Future<void> _runMusicOp(Future<void> Function() op) {
    _musicOpChain = _musicOpChain.then((_) => op()).catchError((_) {});
    return _musicOpChain;
  }

  /// Starts the background music loop. Safe to call multiple times — only
  /// the first call (or a resume after [setMusicEnabled]) actually plays.
  ///
  /// Called from SplashScreen.initState() the instant the app launches —
  /// the same moment the constructor kicks off [_loadPrefs] — so without
  /// waiting for it here, this would read [_musicEnabled]'s default `true`
  /// before the saved "Background Music" preference has actually loaded,
  /// starting the music on every cold start regardless of that setting.
  Future<void> playBackgroundMusic() async {
    await _prefsLoaded;
    if (!_musicEnabled || _musicStarted) return;
    _musicStarted = true;
    await _runMusicOp(() => _musicPlayer.play(AssetSource(_musicAsset), volume: 0.35));
  }

  Future<void> pauseBackgroundMusic() => _runMusicOp(() => _musicPlayer.pause());

  Future<void> resumeBackgroundMusic() {
    if (!_musicEnabled) return Future.value();
    return _runMusicOp(() => _musicPlayer.resume());
  }

  /// On Android's SoundPool (used via PlayerMode.lowLatency), there's no
  /// native playback-completion callback, so the plugin's internal "playing"
  /// flag never resets to false once a sound has been triggered — a later
  /// resume() alone becomes a silent no-op, which is why the sound only ever
  /// played once. stop() (as ReleaseMode.stop, which keeps the preloaded
  /// source/player alive rather than releasing it) resets that flag, so it's
  /// called right before resume() on every trigger.
  Future<void> playWordFoundSound() async {
    if (!_effectsEnabled) return;
    try {
      if (_effectSourceReady) {
        await _effectPlayer.stop();
        await _effectPlayer.resume();
      } else {
        await _effectPlayer.play(AssetSource(_wordFoundAsset), volume: 0.9);
      }
    } catch (_) {
      // Best-effort — a missed sound effect shouldn't affect gameplay.
    }
  }

  /// Buzzes on word-found, gated by the "Haptic Feedback" setting — mirrors
  /// [playWordFoundSound]'s "Sound Effects" gating but is otherwise
  /// independent, so either can be toggled off without touching the other.
  void triggerWordFoundHaptic() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _musicPlayer.dispose();
    _effectPlayer.dispose();
  }
}
