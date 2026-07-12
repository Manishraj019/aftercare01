import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceState {
  final bool isClockedIn;
  final bool isOnBreak;
  final DateTime? clockInTime;
  final Duration totalHours;
  final Set<String> attendedDates; // 'yyyy-MM-dd' format

  const AttendanceState({
    this.isClockedIn = false,
    this.isOnBreak = false,
    this.clockInTime,
    this.totalHours = Duration.zero,
    this.attendedDates = const {},
  });

  AttendanceState copyWith({
    bool? isClockedIn,
    bool? isOnBreak,
    DateTime? clockInTime,
    Duration? totalHours,
    Set<String>? attendedDates,
  }) {
    return AttendanceState(
      isClockedIn: isClockedIn ?? this.isClockedIn,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      clockInTime: clockInTime ?? this.clockInTime,
      totalHours: totalHours ?? this.totalHours,
      attendedDates: attendedDates ?? this.attendedDates,
    );
  }
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  AttendanceViewModel() : super(const AttendanceState()) {
    // Seed some demo past attendance so calendar looks populated
    _seedDemoAttendance();
  }

  void _seedDemoAttendance() {
    final now = DateTime.now();
    final Set<String> seeded = {};
    // Mark most weekdays in the current month as attended
    for (int i = 1; i < now.day; i++) {
      final d = DateTime(now.year, now.month, i);
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        seeded.add(_dateKey(d));
      }
    }
    state = state.copyWith(attendedDates: seeded);
  }

  void clockIn() {
    final now = DateTime.now();
    final today = _dateKey(now);
    final updated = Set<String>.from(state.attendedDates)..add(today);
    state = state.copyWith(
      isClockedIn: true,
      clockInTime: now,
      isOnBreak: false,
      attendedDates: updated,
    );
  }

  void clockOut() {
    final now = DateTime.now();
    Duration additional = Duration.zero;
    if (state.clockInTime != null && !state.isOnBreak) {
      additional = now.difference(state.clockInTime!);
    }
    state = state.copyWith(
      isClockedIn: false,
      isOnBreak: false,
      clockInTime: null,
      totalHours: state.totalHours + additional,
    );
  }

  void startBreak() {
    if (!state.isClockedIn) return;
    final now = DateTime.now();
    Duration additional = Duration.zero;
    if (state.clockInTime != null) {
      additional = now.difference(state.clockInTime!);
    }
    state = state.copyWith(
      isOnBreak: true,
      clockInTime: null,
      totalHours: state.totalHours + additional,
    );
  }

  void endBreak() {
    if (!state.isClockedIn) return;
    state = state.copyWith(isOnBreak: false, clockInTime: DateTime.now());
  }
}

final attendanceViewModelProvider =
    StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  return AttendanceViewModel();
});
