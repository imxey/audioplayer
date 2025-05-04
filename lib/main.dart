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
      title: 'Local Audio Player',
      theme: ThemeData(primarySwatch: Colors.blue),
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

  Widget _buildAudioList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _audioFiles.length,
      itemBuilder: (context, index) {
        final file = _audioFiles[index];
        return ListTile(
          title: Text(p.basename(file.path)),
          trailing:
              _currentFile?.path == file.path ? Icon(Icons.play_arrow) : null,
          onTap: () => _playFile(file),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Local Audio Player")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.upload_file),
              label: Text("Pick and Save Audio"),
              onPressed: _pickAndSaveFile,
            ),
            SizedBox(height: 20),
            if (_currentFile != null)
              Column(
                children: [
                  Text('Now Playing: ${p.basename(_currentFile!.path)}'),
                  ProgressBar(
                    progress: _position,
                    total: _duration,
                    onSeek: _seek,
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                    ),
                    onPressed: _playPause,
                  ),
                ],
              ),
            SizedBox(height: 20),
            Expanded(child: _buildAudioList()),
          ],
        ),
      ),
    );
  }
}
