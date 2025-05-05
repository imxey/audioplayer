import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neumorphic Audio Player',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Color(0xFFEFF3F6),
      ),
      home: AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  List<File> _audioFiles = [];
  File? _currentFile;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();

    _audioPlayer.positionStream.listen((pos) {
      setState(() => _position = pos);
    });

    _audioPlayer.durationStream.listen((dur) {
      setState(() => _duration = dur ?? Duration.zero);
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<void> _loadAudioFiles() async {
    final dir = await _getAudioDir();
    final files = dir.listSync().whereType<File>().toList();
    setState(() {
      _audioFiles = files;
    });
  }

  Future<Directory> _getAudioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(dir.path, 'audios'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  Future<void> _pickAndSaveFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final fileName = p.basename(sourcePath);
      final destDir = await _getAudioDir();
      final destPath = p.join(destDir.path, fileName);

      final newFile = await File(sourcePath).copy(destPath);
      setState(() => _audioFiles.add(newFile));

      _playFile(newFile);
    }
  }

  Future<void> _playFile(File file) async {
    await _audioPlayer.setFilePath(file.path);
    _audioPlayer.play();
    setState(() {
      _currentFile = file;
    });
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _seek(Duration position) {
    _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _neumorphicButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color(0xFFEFF3F6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: Offset(-6, -6),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.grey.shade500,
              offset: Offset(6, 6),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(
                      "assets/album_art.jpg",
                    ), // ganti sesuai asset kamu
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _neumorphicButton(Icons.skip_previous, () {}),
                  SizedBox(width: 30),
                  _neumorphicButton(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    _playPause,
                  ),
                  SizedBox(width: 30),
                  _neumorphicButton(Icons.skip_next, () {}),
                ],
              ),
              SizedBox(height: 20),
              ProgressBar(
                progress: _position,
                total: _duration,
                onSeek: _seek,
                timeLabelTextStyle: TextStyle(color: Colors.grey.shade700),
                thumbColor: Colors.blueGrey,
                baseBarColor: Colors.grey.shade300,
                progressBarColor: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _audioFiles.length,
                  itemBuilder: (context, index) {
                    final file = _audioFiles[index];
                    final fileName = p.basenameWithoutExtension(file.path);

                    return ListTile(
                      leading: Image.asset(
                        'assets/thumb_${(index % 5) + 1}.jpg', // thumb_1.jpg - thumb_5.jpg
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                      title: Text(fileName),
                      onTap: () => _playFile(file),
                    );
                  },
                ),
              ),

              Text("Volume"),
              Slider(
                min: 0,
                max: 1,
                value: _audioPlayer.volume,
                onChanged: (value) => _audioPlayer.setVolume(value),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file),
                label: Text("Pick and Save Audio"),
                onPressed: _pickAndSaveFile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
