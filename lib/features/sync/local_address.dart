import 'dart:io';

/// The address of this computer on the local network, for the QR code. Prefers
/// the usual home / office ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x).
/// Returns null when the computer is not on any network.
Future<String?> bestLocalAddress() async {
  final addresses = <String>[];
  for (final ni in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  )) {
    for (final a in ni.addresses) {
      if (!a.isLoopback && !a.isLinkLocal) {
        addresses.add(a.address);
      }
    }
  }
  return pickLocalAddress(addresses);
}

/// Chooses the most likely LAN address from [addresses].
String? pickLocalAddress(List<String> addresses) {
  bool private(String a) {
    final p = a.split('.').map(int.tryParse).toList();
    if (p.length != 4 || p.contains(null)) {
      return false;
    }
    return p[0] == 192 && p[1] == 168 ||
        p[0] == 10 ||
        (p[0] == 172 && p[1]! >= 16 && p[1]! <= 31);
  }

  final lan = addresses.where(private).toList();
  // 192.168 first: the most common for Wi-Fi routers and phone hotspots.
  lan.sort(
    (a, b) =>
        (b.startsWith('192.168.') ? 1 : 0) - (a.startsWith('192.168.') ? 1 : 0),
  );
  if (lan.isNotEmpty) {
    return lan.first;
  }
  return addresses.isEmpty ? null : addresses.first;
}
