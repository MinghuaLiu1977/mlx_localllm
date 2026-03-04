class DownloadProgress {
  final String repoId;
  final double progress; // 0.0 ~ 1.0
  final String? error;
  final bool isDone;
  final String? path;

  const DownloadProgress({
    required this.repoId,
    required this.progress,
    this.error,
    this.isDone = false,
    this.path,
  });

  @override
  String toString() =>
      'DownloadProgress(repoId: $repoId, progress: $progress, isDone: $isDone, error: $error)';
}
