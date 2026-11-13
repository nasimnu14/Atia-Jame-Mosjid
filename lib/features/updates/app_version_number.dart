/// A version like 1.3.0 (a leading "v", `-beta` and `+build` parts are allowed).
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, [this.preRelease]);
  final int major;
  final int minor;
  final int patch;

  /// e.g. "beta.1"; a pre-release is older than the same version without it.
  final String? preRelease;

  static final _re = RegExp(
    r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.\-]+))?(?:\+.*)?$',
  );

  static AppVersion? tryParse(String text) {
    final m = _re.firstMatch(text.trim());
    if (m == null) {
      return null;
    }
    return AppVersion(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      m[4],
    );
  }

  @override
  int compareTo(AppVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (pair.$1 != pair.$2) {
        return pair.$1.compareTo(pair.$2);
      }
    }
    if (preRelease == other.preRelease) {
      return 0;
    }
    if (preRelease == null) {
      return 1;
    }
    if (other.preRelease == null) {
      return -1;
    }
    return preRelease!.compareTo(other.preRelease!);
  }

  bool operator >(AppVersion o) => compareTo(o) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() =>
      '$major.$minor.$patch${preRelease == null ? '' : '-$preRelease'}';
}
