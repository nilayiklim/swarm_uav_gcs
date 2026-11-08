import 'package:flutter/material.dart';
import 'theme.dart';

/// Örnek (mock) İHA verisi. Canlı veri bağlanınca bu liste Zenoh'tan beslenecek.
class UavInfo {
  const UavInfo({
    required this.name,
    required this.pct,
    required this.bat,
    required this.alt,
    required this.speed,
    required this.vspeed,
    required this.heading,
    required this.roll,
    required this.pitch,
    this.gps = 11,
    this.hdop = 1.1,
    this.bad = false,
    this.tag,
  });

  final String name;
  final int pct;
  final double bat; // V
  final double alt; // m
  final double speed; // m/s
  final double vspeed; // m/s
  final double heading; // °
  final double roll; // °
  final double pitch; // °
  final int gps;
  final double hdop;
  final bool bad;
  final String? tag;

  Color get pctColor => bad ? C.red : C.green;
}

const kUavs = [
  UavInfo(name: 'İHA-1', pct: 88, bat: 15.8, alt: 37.7, speed: 10.1, vspeed: 0.0, heading: 112, roll: -2.1, pitch: 1.4),
  UavInfo(name: 'İHA-2', pct: 76, bat: 15.1, alt: 37.5, speed: 10.1, vspeed: 0.1, heading: 108, roll: 1.3, pitch: 0.8),
  UavInfo(
    name: 'İHA-3',
    pct: 64,
    bat: 14.6,
    alt: 37.7,
    speed: 10.1,
    vspeed: -0.2,
    heading: 95,
    roll: -4.6,
    pitch: 2.2,
    bad: true,
    tag: 'AYRILDI · MAVİ ALAN 12s',
  ),
];
