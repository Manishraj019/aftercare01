import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/staff/presentation/viewmodels/attendance_viewmodel.dart';
import 'package:restaurantos/features/staff/presentation/viewmodels/inventory_viewmodel.dart';

// ── Waiter Portal Color Palette ───────────────
const Color _bg      = Color(0xFF0D0F1A);
const Color _panel   = Color(0xFF161929);
const Color _card    = Color(0xFF1E2235);
const Color _border  = Color(0xFF2D3148);
const Color _white   = Color(0xFFECEDF5);
const Color _muted   = Color(0xFF7B7F99);
const Color _purple  = Color(0xFF8B5CF6);
const Color _cyan    = Color(0xFF06B6D4);
const Color _blue    = Color(0xFF4F8EF7);
const Color _red     = Color(0xFFEF4444);
const Color _amber   = Color(0xFFF59E0B);
const Color _green   = Color(0xFF22C55E);

class WaiterDashboardScreen extends ConsumerStatefulWidget {
  const WaiterDashboardScreen({super.key});
  @override
  ConsumerState<WaiterDashboardScreen> createState() => _WaiterDashboardScreenState();
}

class _WaiterDashboardScreenState extends ConsumerState<WaiterDashboardScreen> {
  // Which month is the calendar viewing
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final authState     = ref.watch(authViewModelProvider);
    final userName      = (authState is Authenticated) ? authState.user.name : 'Staff';
    final attendance    = ref.watch(attendanceViewModelProvider);
    final inventory     = ref.watch(inventoryViewModelProvider);
    final lowStock      = inventory.where((i) => i.isLowStock).toList();
    final presentDays   = attendance.attendedDates.length;

    return Material(
      color: _bg,
      child: CustomScrollView(
        slivers: [
          _appBar(userName),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _attendanceSection(attendance),
                const SizedBox(height: 24),
                _calendarSection(attendance.attendedDates, presentDays),
                const SizedBox(height: 24),
                _statsGrid(),
                const SizedBox(height: 24),
                if (lowStock.isNotEmpty) _lowStockSection(lowStock),
                if (lowStock.isNotEmpty) const SizedBox(height: 24),
                _inventorySection(inventory),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────
  SliverAppBar _appBar(String userName) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _panel,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, color: _purple, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Waiter Portal',
              style: GoogleFonts.poppins(
                  color: _white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        Center(
          child: Text('Hi, $userName 👋',
              style: GoogleFonts.karla(color: _muted, fontSize: 14)),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            ref.read(authViewModelProvider.notifier).logout();
            context.go('/login');
          },
          icon: const Icon(Icons.logout, color: _muted, size: 16),
          label: Text('Sign Out', style: GoogleFonts.karla(color: _muted)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Attendance Buttons ────────────────────
  Widget _attendanceSection(AttendanceState att) {
    String statusLabel;
    Color statusColor;
    if (!att.isClockedIn) {
      statusLabel = 'CLOCKED OUT'; statusColor = _red;
    } else if (att.isOnBreak) {
      statusLabel = 'ON BREAK'; statusColor = _amber;
    } else {
      statusLabel = 'ON DUTY'; statusColor = _green;
    }

    final h = att.totalHours.inHours;
    final m = att.totalHours.inMinutes.remainder(60);

    return _panelCard(
      borderColor: _purple,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: _purple, size: 18),
                const SizedBox(width: 8),
                Text('ATTENDANCE',
                    style: GoogleFonts.karla(
                        color: _purple, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Spacer(),
                _badge(statusLabel, statusColor),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _attBtn('Clock In',   Icons.login,   !att.isClockedIn,       _green,
                    () => ref.read(attendanceViewModelProvider.notifier).clockIn()),
                const SizedBox(width: 10),
                _attBtn('Clock Out',  Icons.logout,  att.isClockedIn,        _red,
                    () => ref.read(attendanceViewModelProvider.notifier).clockOut()),
                const SizedBox(width: 10),
                _attBtn(att.isOnBreak ? 'End Break' : 'Break', Icons.coffee_rounded,
                    att.isClockedIn, _amber, () {
                  if (att.isOnBreak) {
                    ref.read(attendanceViewModelProvider.notifier).endBreak();
                  } else {
                    ref.read(attendanceViewModelProvider.notifier).startBreak();
                  }
                }),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Today', style: GoogleFonts.karla(color: _muted, fontSize: 11)),
                    Text('${h}h ${m}m',
                        style: GoogleFonts.poppins(
                            color: _white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attBtn(String label, IconData icon, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : _border.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color.withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? color : _muted),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.karla(
                    color: active ? color : _muted, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: GoogleFonts.karla(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // ── Attendance Calendar ───────────────────
  Widget _calendarSection(Set<String> attendedDates, int presentCount) {
    final now   = DateTime.now();
    final year  = _calendarMonth.year;
    final month = _calendarMonth.month;

    // Days in this month
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // Weekday of the 1st (Mon=1, Sun=7 → shift to Sun=0 for display)
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sun=0..Sat=6

    final monthNames = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];

    // Count present days in this viewed month
    final monthKey = '${year.toString()}-${month.toString().padLeft(2, '0')}';
    final monthPresent = attendedDates.where((d) => d.startsWith(monthKey)).length;
    final workingDays = _workingDaysInMonth(year, month, now);

    return _panelCard(
      borderColor: _cyan,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: _cyan, size: 18),
                const SizedBox(width: 8),
                Text('ATTENDANCE CALENDAR',
                    style: GoogleFonts.karla(
                        color: _cyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Spacer(),
                // Summary chips
                _calChip('$presentCount days', Icons.check_circle_rounded, _green),
                const SizedBox(width: 8),
                _calChip('${workingDays - monthPresent} absent', Icons.cancel_rounded, _red),
              ],
            ),
            const SizedBox(height: 20),

            // ── Month Navigation ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: _white),
                  onPressed: () => setState(() {
                    _calendarMonth = DateTime(year, month - 1);
                  }),
                ),
                Text('${monthNames[month - 1]}  $year',
                    style: GoogleFonts.poppins(
                        color: _white, fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded,
                      color: month == now.month && year == now.year ? _muted : _white),
                  onPressed: (month == now.month && year == now.year)
                      ? null
                      : () => setState(() {
                            _calendarMonth = DateTime(year, month + 1);
                          }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Day-of-week headers ──
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: GoogleFonts.karla(
                                  color: _muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // ── Calendar Grid ──
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firstWeekday + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox.shrink();

                final day    = index - firstWeekday + 1;
                final date   = DateTime(year, month, day);
                final key    = '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final isPresent  = attendedDates.contains(key);
                final isToday    = day == now.day && month == now.month && year == now.year;
                final isFuture   = date.isAfter(now);
                final isWeekend  = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

                Color bg;
                Color textColor;
                Widget? badge;

                if (isToday) {
                  bg = _cyan;
                  textColor = Colors.black;
                } else if (isPresent) {
                  bg = _green.withOpacity(0.2);
                  textColor = _green;
                  badge = Positioned(
                    bottom: 4,
                    child: Container(
                      width: 5, height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _green,
                      ),
                    ),
                  );
                } else if (isFuture) {
                  bg = Colors.transparent;
                  textColor = _muted.withOpacity(0.4);
                } else if (isWeekend) {
                  bg = Colors.transparent;
                  textColor = _muted.withOpacity(0.6);
                } else {
                  // Past working day — absent
                  bg = _red.withOpacity(0.08);
                  textColor = _red.withOpacity(0.6);
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: _cyan, width: 2)
                            : isPresent
                                ? Border.all(color: _green.withOpacity(0.5))
                                : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day',
                                style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontWeight: isToday || isPresent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13)),
                            if (isPresent && !isToday)
                              Container(
                                width: 5, height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _green,
                                ),
                              ),
                            if (isToday)
                              Container(
                                width: 5, height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            // ── Legend ──
            Row(
              children: [
                _legendDot(_green,  'Present'),
                const SizedBox(width: 16),
                _legendDot(_cyan,   'Today'),
                const SizedBox(width: 16),
                _legendDot(_red.withOpacity(0.6), 'Absent'),
                const SizedBox(width: 16),
                _legendDot(_muted.withOpacity(0.5), 'Weekend'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.karla(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.karla(color: _muted, fontSize: 12)),
      ],
    );
  }

  int _workingDaysInMonth(int year, int month, DateTime now) {
    final days = DateUtils.getDaysInMonth(year, month);
    final upTo = (month == now.month && year == now.year) ? now.day : days;
    int count = 0;
    for (int i = 1; i <= upTo; i++) {
      final d = DateTime(year, month, i);
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) count++;
    }
    return count;
  }

  // ── Stats Grid ────────────────────────────
  Widget _statsGrid() {
    return LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: [
            _statCard('Tables Occupied',   '8 / 24', Icons.table_restaurant,       _cyan),
            _statCard('Active Sessions',   '12',     Icons.groups_rounded,          _blue),
            _statCard('Pending Orders',    '5',      Icons.receipt_long_rounded,    _red),
            _statCard('Purchase Requests', '2',      Icons.shopping_cart_rounded,   _amber),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      color: _white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: GoogleFonts.karla(color: _muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Low Stock Alerts ──────────────────────
  Widget _lowStockSection(List<InventoryItem> items) {
    return _panelCard(
      borderColor: _red,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
                const SizedBox(width: 8),
                Text('LOW STOCK ALERTS',
                    style: GoogleFonts.karla(
                        color: _red, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
                  label: Text('Generate PO',
                      style: GoogleFonts.karla(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: _red, size: 15),
                  const SizedBox(width: 10),
                  Text(item.name, style: GoogleFonts.karla(color: _white, fontSize: 14)),
                  const Spacer(),
                  Text('${item.currentQuantity} / ${item.minQuantity} ${item.unit}',
                      style: GoogleFonts.karla(color: _red, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ── Inventory Table ───────────────────────
  Widget _inventorySection(List<InventoryItem> inventory) {
    return _panelCard(
      borderColor: _cyan,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_rounded, color: _cyan, size: 18),
                const SizedBox(width: 8),
                Text('INVENTORY',
                    style: GoogleFonts.karla(
                        color: _cyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 14),
            // Table header
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Ingredient', style: GoogleFonts.karla(color: _muted, fontSize: 12))),
                  SizedBox(width: 90, child: Text('Stock', style: GoogleFonts.karla(color: _muted, fontSize: 12), textAlign: TextAlign.right)),
                  SizedBox(width: 70, child: Text('Min', style: GoogleFonts.karla(color: _muted, fontSize: 12), textAlign: TextAlign.right)),
                  SizedBox(width: 80, child: Text('Status', style: GoogleFonts.karla(color: _muted, fontSize: 12), textAlign: TextAlign.right)),
                ],
              ),
            ),
            Container(height: 1, color: _border),
            const SizedBox(height: 8),
            ...inventory.map((item) {
              final ok = !item.isLowStock;
              final color = ok ? _green : _red;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(item.name, style: GoogleFonts.karla(color: _white))),
                    SizedBox(
                      width: 90,
                      child: Text('${item.currentQuantity} ${item.unit}',
                          style: GoogleFonts.karla(color: _white), textAlign: TextAlign.right),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text('${item.minQuantity} ${item.unit}',
                          style: GoogleFonts.karla(color: _muted), textAlign: TextAlign.right),
                    ),
                    SizedBox(
                      width: 80,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(ok ? 'OK' : 'LOW',
                              style: GoogleFonts.karla(
                                  color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Shared panel card ─────────────────────
  Widget _panelCard({required Widget child, Color borderColor = const Color(0xFF2D3148)}) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: child,
    );
  }
}
