enum CanvasBackgroundPattern {
  /// No background pattern
  none(''),

  /// Horizontal lines
  lined('lined'),

  /// A grid of dots
  dots('dots', requiresClipping: true);

  const CanvasBackgroundPattern(this.name, {this.requiresClipping = false});

  /// The pattern name used for serialization.
  /// Do not display this to the user: instead use [localizedName].
  final String name;

  /// Whether this pattern has elements along the page edges that may need to be
  /// clipped.
  final bool requiresClipping;

  static CanvasBackgroundPattern fromName(String? name) {
    return values.firstWhere(
      (pattern) => pattern.name == name,
      orElse: () => CanvasBackgroundPattern.none,
    );
  }
}
