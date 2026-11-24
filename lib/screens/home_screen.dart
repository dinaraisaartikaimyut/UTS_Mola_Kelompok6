import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import 'task_form_screen.dart';

enum TaskFilter { all, active, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary = Color(0xFF6558D3);
  static const Color _dark = Color(0xFF292640);
  static const Color _grey = Color(0xFF858198);

  List<Task> _tasks = [];
  String _userName = '';
  bool _loading = true;
  TaskFilter _filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final name = await AuthService.getUserName();
    final tasks = await TaskService.loadTasks();
    if (!mounted) return;
    setState(() {
      _userName = name ?? 'User';
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _persist() => TaskService.saveTasks(_tasks);

  List<Task> get _visibleTasks {
    final list = _tasks.where((t) {
      switch (_filter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.active:
          return !t.isDone;
        case TaskFilter.done:
          return t.isDone;
      }
    }).toList();

    list.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return list;
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  // ---------- Actions ----------

  Future<void> _openPage(String route) async {
    await Navigator.pushNamed(context, route);
    if (!mounted) return;
    // Muat ulang karena task bisa berubah dari halaman lain.
    final tasks = await TaskService.loadTasks();
    if (!mounted) return;
    setState(() => _tasks = tasks);
  }

  Future<void> _openTaskForm({Task? task}) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );

    if (result == null) return;

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == result.id);
      if (index >= 0) {
        _tasks[index] = result;
      } else {
        _tasks.add(result);
      }
    });
    await _persist();
  }

  Future<void> _toggleDone(Task task) async {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      _tasks[index] = task.copyWith(isDone: !task.isDone);
    });
    await _persist();
  }

  Future<bool> _confirmDelete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus task?'),
        content: Text('Task "${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task dihapus')),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isDone).length;
    final pending = total - done;
    final overdue = _tasks.where((t) => t.isOverdue).length;
    final progress = total == 0 ? 0.0 : done / total;
    final visible = _visibleTasks;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Task Baru'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildProgressCard(progress, done, total),
                      const SizedBox(height: 16),
                      _buildStats(total, pending, done, overdue),
                      const SizedBox(height: 24),
                      _buildFilterChips(),
                      const SizedBox(height: 12),
                      if (visible.isEmpty)
                        _buildEmpty()
                      else
                        ...visible.map(_buildTaskTile),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _openPage('/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: _primary,
            child: Text(
              _userName.isEmpty ? '?' : _userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: const TextStyle(color: _grey, fontSize: 13)),
              Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _dark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Kalender',
          onPressed: () => _openPage('/calendar'),
          icon: const Icon(Icons.calendar_month_outlined, color: _dark),
        ),
      ],
    );
  }

  Widget _buildProgressCard(double progress, int done, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Tugas',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            total == 0 ? 'Belum ada task' : '$done dari $total selesai',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int total, int pending, int done, int overdue) {
    Widget stat(String label, int value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: _grey)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat('Total', total, Icons.list_alt_rounded, _primary),
        const SizedBox(width: 10),
        stat('Aktif', pending, Icons.pending_actions_rounded, Colors.orange),
        const SizedBox(width: 10),
        stat('Selesai', done, Icons.check_circle_rounded, Colors.green),
        const SizedBox(width: 10),
        stat('Telat', overdue, Icons.warning_amber_rounded, Colors.red),
      ],
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, TaskFilter f) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == f,
          selectedColor: _primary,
          labelStyle: TextStyle(
            color: _filter == f ? Colors.white : _dark,
            fontWeight: FontWeight.w600,
          ),
          showCheckmark: false,
          onSelected: (_) => setState(() => _filter = f),
        ),
      );
    }

    return Row(
      children: [
        const Text(
          'Daftar Task',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
        ),
        const Spacer(),
        chip('Semua', TaskFilter.all),
        chip('Aktif', TaskFilter.active),
        chip('Selesai', TaskFilter.done),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: const [
          Icon(Icons.inbox_outlined, size: 64, color: Color(0xFFB9B5CC)),
          SizedBox(height: 12),
          Text(
            'Belum ada task di sini',
            style: TextStyle(color: _grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(task),
      onDismissed: (_) => _deleteTask(task),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onTap: () => _openTaskForm(task: task),
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
          subtitle: (task.note.isEmpty && task.dueDate == null)
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
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 14,
                              color: task.isOverdue ? Colors.red : _grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(task.dueDate!) +
                                  (task.isOverdue ? ' • Terlambat' : ''),
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isOverdue ? Colors.red : _grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          trailing: IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline, color: _grey),
            onPressed: () async {
              if (await _confirmDelete(task)) _deleteTask(task);
            },
          ),
        ),
      ),
    );
  }
}
