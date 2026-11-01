import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../offline/offline.dart';
import 'models.dart';
import 'songs_repository.dart';

part 'songs_providers.g.dart';

@Riverpod(keepAlive: true)
SongsRepository songsRepository(Ref ref) =>
    SongsRepository(ref.watch(supabaseProvider), ref.watch(readThroughProvider));

@riverpod
Future<List<SongEntry>> songLibrary(Ref ref, int teamId) =>
    ref.watch(songsRepositoryProvider).library(teamId);

@riverpod
Future<SongDetail> songDetail(Ref ref, int songId) =>
    ref.watch(songsRepositoryProvider).detail(songId);

/// A song's versions with their sheets, for choosing what a service plays.
@riverpod
Future<List<SongVersion>> songVersions(Ref ref, int songId) =>
    ref.watch(songsRepositoryProvider).versions(songId);

@riverpod
Future<Sheet> sheet(Ref ref, int sheetId) => ref.watch(songsRepositoryProvider).sheet(sheetId);

/// PDF bytes, kept for the session (sheet files never change in place:
/// a new upload gets a new path).
@Riverpod(keepAlive: true)
Future<Uint8List> sheetBytes(Ref ref, String storagePath) =>
    ref.watch(songsRepositoryProvider).downloadSheet(storagePath);

enum StatsPeriod { months3, months6, year1, all }

@riverpod
Future<List<TopSong>> topSongs(Ref ref, int teamId, StatsPeriod period) {
  final now = DateTime.now();
  final from = switch (period) {
    StatsPeriod.months3 => DateTime(now.year, now.month - 3, now.day),
    StatsPeriod.months6 => DateTime(now.year, now.month - 6, now.day),
    StatsPeriod.year1 => DateTime(now.year - 1, now.month, now.day),
    StatsPeriod.all => DateTime(2000),
  };
  return ref.watch(songsRepositoryProvider).topSongs(teamId, from, now.add(const Duration(days: 1)));
}
