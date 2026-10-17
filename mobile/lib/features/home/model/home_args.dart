/// Route arguments passed to the Home screen, if any.
class HomeArgs {
  const HomeArgs({
    this.initialTab = 0,
    this.source,
  });

  final int initialTab;
  final String? source;
}
