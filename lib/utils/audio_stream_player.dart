import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioStreamPlayer {
  final _audioPlayer = AudioPlayer();
  StreamSubscription? _audioStreamSubscription;
  bool _isPlaying = false;
  //todo: might need to adjust this
  final int _sampleRate = 8000;
  Timer? _bufferTimer;
  final List<int> _pcmBuffer = [];

  Future<void> initialize() async {
    final session = await AudioSession.instance;

    // Configure for background playback
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media, // Allows background playback
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );

    _audioPlayer.playerStateStream.listen((state) {
      debugPrint('Audio player state: ${state.processingState} - ${state.playing}');
    });

    _audioPlayer.positionStream.listen((position) {
      debugPrint('Audio position: $position');
    });
  }

  void start(Stream<int> dataStream) {
    if (_isPlaying) return;
    _isPlaying = true;
    _pcmBuffer.clear();

    try {
      debugPrint('Starting audio stream player');

      _bufferTimer = Timer(Duration(seconds: 1), () {
        if (_pcmBuffer.isNotEmpty) {
          debugPrint('Buffer timer triggered with ${_pcmBuffer.length} samples');
          _playBufferedAudio();
        } else {
          debugPrint('Buffer timer triggered but buffer is empty');
        }
      });

      _audioStreamSubscription = dataStream.listen(
        (value) {
          final scaledValue = (value * 327.67).toInt();
          _pcmBuffer.add(scaledValue);

          if (_pcmBuffer.length % 100 == 0) {
            debugPrint('Buffer size: ${_pcmBuffer.length} samples, last value: $value');
          }
        },
        onError: (e) {
          debugPrint('Stream error: $e');
          stop();
        },
        onDone: () {
          debugPrint('Stream completed with ${_pcmBuffer.length} samples');
          _bufferTimer?.cancel();
          _playBufferedAudio();
        },
      );
    } catch (e) {
      debugPrint('AudioStreamPlayer start error: $e');
      stop();
    }
  }

  void _playBufferedAudio() {
    if (_pcmBuffer.isEmpty) {
      debugPrint('No audio data to play');
      return;
    }

    try {
      debugPrint('Creating WAV from ${_pcmBuffer.length} samples');
      final wavBytes = _createWavFile(_pcmBuffer);
      debugPrint('WAV file created, size: ${wavBytes.length} bytes');

      final wavSource = BytesSource(wavBytes);

      _audioPlayer.setAudioSource(wavSource).then((_) {
        debugPrint('Audio source set successfully');
        _audioPlayer.play().then((_) {
          debugPrint('Play command issued');
        }).catchError((e) {
          debugPrint('Error playing audio: $e');
        });
      }).catchError((e) {
        debugPrint('Error setting audio source: $e');
      });
    } catch (e) {
      debugPrint('Error preparing audio: $e');
    }
  }

  void stop() {
    debugPrint('Stopping audio player');
    _isPlaying = false;
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    _bufferTimer?.cancel();
    _bufferTimer = null;
    _pcmBuffer.clear();
    _audioPlayer.stop();
  }

  Uint8List _createWavFile(List<int> pcmData) {
    final channels = 1;
    final bitsPerSample = 16;

    final bytesPerSample = bitsPerSample ~/ 8;
    final byteRate = _sampleRate * channels * bytesPerSample;
    final blockAlign = channels * bytesPerSample;
    final dataSize = pcmData.length * bytesPerSample;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);

    header.setUint8(0, 'R'.codeUnitAt(0));
    header.setUint8(1, 'I'.codeUnitAt(0));
    header.setUint8(2, 'F'.codeUnitAt(0));
    header.setUint8(3, 'F'.codeUnitAt(0));
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 'W'.codeUnitAt(0));
    header.setUint8(9, 'A'.codeUnitAt(0));
    header.setUint8(10, 'V'.codeUnitAt(0));
    header.setUint8(11, 'E'.codeUnitAt(0));

    header.setUint8(12, 'f'.codeUnitAt(0));
    header.setUint8(13, 'm'.codeUnitAt(0));
    header.setUint8(14, 't'.codeUnitAt(0));
    header.setUint8(15, ' '.codeUnitAt(0));
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    header.setUint8(36, 'd'.codeUnitAt(0));
    header.setUint8(37, 'a'.codeUnitAt(0));
    header.setUint8(38, 't'.codeUnitAt(0));
    header.setUint8(39, 'a'.codeUnitAt(0));
    header.setUint32(40, dataSize, Endian.little);

    final outputBuffer = ByteData(44 + pcmData.length * 2);

    for (var i = 0; i < 44; i++) {
      outputBuffer.setUint8(i, header.getUint8(i));
    }

    for (var i = 0; i < pcmData.length; i++) {
      final sample = pcmData[i].clamp(-32768, 32767);
      outputBuffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return outputBuffer.buffer.asUint8List();
  }

  dispose() {
    stop();
    _audioPlayer.dispose();
  }
}

class BytesSource extends StreamAudioSource {
  final Uint8List _bytes;

  BytesSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start = start ?? 0;
    end = end ?? _bytes.length;

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}