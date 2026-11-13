import 'desktop_shell.dart';

/// Lets a screen inside the desktop shell switch to another menu section
/// (for example the dashboard's "View summary").
class ShellController {
  const ShellController(this.goTo);
  final void Function(Section section) goTo;
}
