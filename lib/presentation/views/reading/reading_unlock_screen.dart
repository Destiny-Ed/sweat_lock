import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

/// Read [requiredReadingPages] unique pages to unlock (alternative to workout).
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
  final Set<int> _visited = {};
  int _pageCount = 0;
  bool _loading = true;
  String? _error;
  bool _unlocking = false;

  int get _needed => requiredReadingPages;

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
            'No book PDF found. Upload one in Settings → Reading unlock.';
      });
      return;
    }

    try {
      final doc = PdfDocument.openFile(path);
      _controller = PdfControllerPinch(document: doc);
      final opened = await doc;
      setState(() {
        _pageCount = opened.pagesCount;
        _loading = false;
        _visited.add(1);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not open PDF. Try uploading again.';
      });
    }
  }

  Future<void> _tryUnlock() async {
    if (_visited.length < _needed || _unlocking) return;
    setState(() => _unlocking = true);

    final mins = HiveService.getUnlockDurationMinutes();
    if (Platform.isIOS) {
      await IosNudgeService.instance.onWorkoutCompleted(unlockMinutes: mins);
    } else if (Platform.isAndroid) {
      BlockingService.instance.grantCurrentUnlock(minutes: mins);
      await BlockingService.instance.startListening();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unlocked — keep reading next time too!')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_visited.length / _needed).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.appName ?? 'Read to unlock'),
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          Text(
                            'Read $_needed pages to unlock'
                            '${_pageCount > 0 ? ' · $_pageCount in book' : ''}',
                            style: const TextStyle(color: Colors.white70),
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
                            '${_visited.length} / $_needed pages viewed',
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PdfViewPinch(
                        controller: _controller!,
                        onPageChanged: (page) {
                          setState(() => _visited.add(page));
                          if (_visited.length >= _needed) {
                            _tryUnlock();
                          }
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _visited.length >= _needed && !_unlocking
                                ? _tryUnlock
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _visited.length >= _needed
                                  ? 'Unlock now'
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
                ),
    );
  }
}
