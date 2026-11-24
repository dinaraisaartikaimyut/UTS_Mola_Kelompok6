import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import 'task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _primary = Color(0xFF6558D3);
  static const Color _dark = Color(0xFF292640);
  static const Color _grey = Color(0xFF858198);

  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _weekdays = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  List<Task> _tasks = [];
  bool _loading = true;
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _init();
  }

  Future<void> _init() async {
    final tasks = await TaskService.loadTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _persist() => TaskService.saveTasks(_tasks);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Task> _tasksOn(DateTime day) {
    final list = _tasks
        .where((t) => t.dueDate != null && _sameDay(t.dueDate!, day))
        .toList();
    list.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }

  String _formatDate(DateTime d) {
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  Future<void> _toggleDone(Task task) async {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      _tasks[index] = task.copyWith(isDone: !task.isDone);
    });
    await _persist();
  }

  Future<void> _openTaskForm(Task task) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );

    if (result == null) return;

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == result.id);
      if (index >= 0) _tasks[index] = result;
    });
    await _persist();
  }

  // Warna penanda di bawah tanggal: merah = ada yang telat,
  // ungu = ada yang masih aktif, hijau = semua selesai.
  Color? _markerColor(DateTime day) {
    final list = _tasksOn(day);
    if (list.isEmpty) return null;
    if (list.any((t) => t.isOverdue)) return Colors.red;
    if (list.any((t) => !t.isDone)) return _primary;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _tasksOn(_selected);
    final noDeadline = _tasks.where((t) => t.dueDate == null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _dark,
        actions: [
          IconButton(
            tooltip: 'Hari ini',
            onPressed: _goToday,
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _buildCalendarCard(),
                      const SizedBox(height: 24),
                      Text(
                        _formatDate(_selected),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedTasks.isEmpty)
                        _buildEmpty()
                      else
                        ...selectedTasks.map(_buildTaskTile),
                      if (noDeadline > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '$noDeadline task tanpa deadline tidak tampil di kalender',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9995AA),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstWeekday - 1;
    final today = DateTime.now();

    final cells = <Widget>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_month.year, _month.month, d);
      final isSelected = _sameDay(day, _selected);
      final isToday = _sameDay(day, today);
      final marker = _markerColor(day);

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selected = day),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: (isToday && !isSelected)
                  ? Border.all(color: _primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: (isSelected || isToday)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isSelected ? Colors.white : _dark,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: marker == null
                        ? Colors.transparent
                        : (isSelected ? Colors.white : marker),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Bulan sebelumnya',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: _dark,
              ),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _dark,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Bulan berikutnya',
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: _dark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _grey,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 64, color: Color(0xFFB9B5CC)),
          SizedBox(height: 12),
          Text(
            'Tidak ada deadline di tanggal ini',
            style: TextStyle(color: _grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => _openTaskForm(task),
        leading: Checkbox(
          value: task.isDone,
          activeColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (_) => _toggleDone(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: task.isDone ? _grey : _dark,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: (task.note.isEmpty && !task.isOverdue)
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.note.isNotEmpty)
                    Text(
                      task.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (task.isOverdue)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Terlambat',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                ],
              ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _grey),
      ),
    );
  }
}
