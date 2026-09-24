import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'package:sweat_lock/services/reading_quiz_service.dart';

/// Phase 1: read N pages with minimum dwell time.
/// Phase 2: answer all quiz questions correctly (from PDF text).
class ReadingUnlockScreen extends StatefulWidget {
  final String? unlockedAppId;
  final String? appName;

  const ReadingUnlockScreen({
    super.key,
    this.unlockedAppId,
    this.appName,
  });

  @override
  State<ReadingUnlockScreen> createState() => _ReadingUnlockScreenState();
}

class _ReadingUnlockScreenState extends State<ReadingUnlockScreen> {
  PdfControllerPinch? _controller;
  final Set<int> _qualifiedPages = {};
  final Map<int, int> _dwellMs = {};
  int _currentPage = 1;
  int _pageCount = 0;
  bool _loading = true;
  String? _error;
  bool _inQuiz = false;
  bool _unlocking = false;
  List<QuizQuestion> _questions = [];
  final Map<int, int> _answers = {};
  Timer? _dwellTimer;
  String? _pdfPath;

  int get _needed => requiredReadingPages;
  int get _dwellNeed => readingDwellSecondsPerPage * 1000;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final path = HiveService.getReadingPdfPath();
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      setState(() {
        _loading = false;
        _error =
            'No book PDF found. Upload one in Settings → Unlock by reading.';
      });
      return;
    }
    _pdfPath = path;

    try {
      final document = PdfDocument.openFile(path);
      _controller = PdfControllerPinch(document: document);
      final opened = await document;
      setState(() {
        _pageCount = opened.pagesCount;
        _loading = false;
        _currentPage = 1;
      });
      _startDwellTicker();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not open PDF. Try uploading again.\n$e';
      });
    }
  }

  void _startDwellTicker() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_inQuiz || !mounted) return;
      final p = _currentPage;
      _dwellMs[p] = (_dwellMs[p] ?? 0) + 1000;
      if ((_dwellMs[p] ?? 0) >= _dwellNeed) {
        if (!_qualifiedPages.contains(p)) {
          setState(() => _qualifiedPages.add(p));
        }
      } else {
        setState(() {});
      }
    });
  }

  int _secondsLeftOnPage() {
    final spent = _dwellMs[_currentPage] ?? 0;
    final left = ((_dwellNeed - spent) / 1000).ceil();
    return left < 0 ? 0 : left;
  }

  /// Resolve the single app this reading session should unlock.
  BlockedApp? _resolveTargetApp() {
    final apps = HiveService.getBlockedApps().where((a) => a.isActive).toList();

    final id = widget.unlockedAppId ?? HiveService.getLastBlockedAppId();
    if (id != null && id.isNotEmpty) {
      for (final a in apps) {
        if (a.id == id) return a;
      }
    }

    final pkg = HiveService.getLastBlockedPackage();
    if (pkg != null && pkg.isNotEmpty) {
      for (final a in apps) {
        if (a.packageName == pkg ||
            a.bundleId == pkg ||
            (a.bundleId.isNotEmpty &&
                (pkg.contains(a.bundleId) || a.bundleId.contains(pkg))) ||
            (a.packageName.isNotEmpty &&
                (pkg.contains(a.packageName) || a.packageName.contains(pkg)))) {
          return a;
        }
      }
    }

    final name = widget.appName;
    if (name != null && name.isNotEmpty) {
      for (final a in apps) {
        if (a.appName.toLowerCase() == name.toLowerCase()) return a;
      }
    }

    if (apps.length == 1) return apps.first;

    for (final a in apps) {
      if (a.bundleId.isNotEmpty) return a;
    }
    return apps.isNotEmpty ? apps.first : null;
  }

  Future<void> _startQuiz() async {
    if (_qualifiedPages.length < _needed || _pdfPath == null) return;
    setState(() => _loading = true);
    try {
      final texts = await ReadingQuizService.instance.extractPageTexts(
        _pdfPath!,
        _qualifiedPages.take(_needed),
      );
      final qs = ReadingQuizService.instance.generate(
        texts,
        count: requiredQuizQuestions,
      );
      setState(() {
        _questions = qs;
        _inQuiz = true;
        _loading = false;
        _answers.clear();
      });
      _dwellTimer?.cancel();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not build quiz from this PDF.\n$e';
      });
    }
  }

  bool get _quizAllCorrect {
    if (_questions.isEmpty) return false;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] != _questions[i].correctIndex) return false;
    }
    return _answers.length == _questions.length;
  }

  Future<void> _tryUnlock() async {
    if (!_quizAllCorrect || _unlocking) return;
    setState(() => _unlocking = true);

    final mins = HiveService.getUnlockDurationMinutes();
    final target = _resolveTargetApp();
    final displayName = widget.appName ?? target?.appName ?? 'App';

    if (target == null) {
      if (Platform.isAndroid) {
        await BlockingService.instance.hideBlockOverlay();
      }
      if (!mounted) return;
      setState(() => _unlocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not identify which app to unlock. Open it again from the lock screen.',
          ),
        ),
      );
      return;
    }

    if (Platform.isAndroid) {
      final package = target.packageName.isNotEmpty
          ? target.packageName
          : HiveService.getLastBlockedPackage();
      if (package == null || package.isEmpty) {
        if (!mounted) return;
        setState(() => _unlocking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing package for unlock')),
        );
        return;
      }
      await BlockingService.instance.grantTemporaryUnlock(
        package,
        minutes: mins,
      );
      await BlockingService.instance.startListening();
    } else if (Platform.isIOS) {
      final bundleId =
          target.bundleId.isNotEmpty ? target.bundleId : null;
      await IosNudgeService.instance.onWorkoutCompleted(
        unlockMinutes: mins,
        bundleId: bundleId,
        unlockAll: false,
      );
    }

    await HiveService.incrementReadingUnlocks();
    await HiveService.addEstimatedMinutesSaved(mins);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$displayName unlocked for $mins min — quiz passed!'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _inQuiz
              ? 'Comprehension quiz'
              : (widget.appName ?? 'Read to unlock'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : _inQuiz
                  ? _buildQuiz()
                  : _buildReader(),
    );
  }

  Widget _buildReader() {
    final progress = (_qualifiedPages.length / _needed).clamp(0.0, 1.0);
    final left = _secondsLeftOnPage();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              Text(
                'Stay on each page ≥ ${readingDwellSecondsPerPage}s · '
                'then pass a quiz on the text',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white24,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 6),
              Text(
                '${_qualifiedPages.length} / $_needed pages qualified'
                '${_pageCount > 0 ? ' · $_pageCount in book' : ''}'
                '${left > 0 ? ' · ${left}s left on this page' : ' · page OK'}',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PdfViewPinch(
            controller: _controller!,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _qualifiedPages.length >= _needed ? _startQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _qualifiedPages.length >= _needed
                      ? 'Take comprehension quiz'
                      : 'Keep reading…',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz() {
    final target = _resolveTargetApp();
    final name = widget.appName ?? target?.appName;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          name != null
              ? 'Answer every question correctly to unlock $name only.'
              : 'Answer every question correctly to unlock the app that was locked.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        ...List.generate(_questions.length, (i) {
          final q = _questions[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${i + 1}. ${q.prompt}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(q.options.length, (oi) {
                  final selected = _answers[i] == oi;
                  return RadioListTile<int>(
                    dense: true,
                    value: oi,
                    groupValue: _answers[i],
                    activeColor: AppColors.primaryGreen,
                    title: Text(
                      q.options[oi],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _answers[i] = v);
                    },
                    selected: selected,
                  );
                }),
              ],
            ),
          );
        }),
        if (_answers.length == _questions.length && !_quizAllCorrect)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Some answers are wrong — try again.',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _quizAllCorrect && !_unlocking ? _tryUnlock : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              _quizAllCorrect
                  ? (name != null ? 'Unlock $name' : 'Unlock app')
                  : 'Answer all correctly',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
