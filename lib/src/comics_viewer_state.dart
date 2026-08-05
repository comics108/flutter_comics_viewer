enum ComicsViewerPhase { idle, loading, loaded, error, unsupported }

class ComicsViewerState {
  const ComicsViewerState({
    this.phase = ComicsViewerPhase.idle,
    this.position = 0,
    this.playing = false,
    this.error,
  });

  final ComicsViewerPhase phase;
  final double position;
  final bool playing;
  final String? error;

  ComicsViewerState copyWith({
    ComicsViewerPhase? phase,
    double? position,
    bool? playing,
    String? error,
    bool clearError = false,
  }) => ComicsViewerState(
    phase: phase ?? this.phase,
    position: position ?? this.position,
    playing: playing ?? this.playing,
    error: clearError ? null : error ?? this.error,
  );
}
