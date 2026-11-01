import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const KharchaApp());

const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

class Cat {
  final String name;
  final IconData icon;
  final Color color;
  const Cat(this.name, this.icon, this.color);
}

const List<Cat> kCategories = [
  Cat('Khana', Icons.restaurant, Colors.orange),
  Cat('Travel', Icons.directions_bus, Colors.blue),
  Cat('Shopping', Icons.shopping_bag, Colors.pink),
  Cat('Bill', Icons.receipt_long, Colors.teal),
  Cat('Recharge', Icons.phone_android, Colors.indigo),
  Cat('Padhai', Icons.menu_book, Colors.brown),
  Cat('Sehat', Icons.local_hospital, Colors.red),
  Cat('Manoranjan', Icons.movie, Colors.purple),
  Cat('Other', Icons.category, Colors.grey),
];

Cat catOf(String name) =>
    kCategories.firstWhere((c) => c.name == name, orElse: () => kCategories.last);

class Expense {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        note: (j['note'] ?? '') as String,
        date: DateTime.parse(j['date'] as String),
      );
}

String rupees(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '₹$s';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d) {
  final now = DateTime.now();
  if (sameDay(d, now)) return 'Aaj';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Kal';
  return '${d.day} ${kMonths[d.month - 1]}';
}

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharcha Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _all = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('expenses');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _all = list
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('expenses', jsonEncode(_all.map((e) => e.toJson()).toList()));
  }

  List<Expense> get _monthList {
    final l = _all
        .where((e) => e.date.year == _month.year && e.date.month == _month.month)
        .toList();
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddExpenseSheet(),
    );
    if (result != null) {
      setState(() {
        _all.add(result);
        _month = DateTime(result.date.year, result.date.month);
      });
      await _save();
    }
  }

  Future<void> _delete(Expense e) async {
    setState(() => _all.removeWhere((x) => x.id == e.id));
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rupees(e.amount)} (${e.category}) delete ho gaya'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            setState(() => _all.add(e));
            await _save();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = _monthList;
    final monthTotal = list.fold<double>(0, (s, e) => s + e.amount);
    final now = DateTime.now();
    final todayTotal = _all
        .where((e) => sameDay(e.date, now))
        .fold<double>(0, (s, e) => s + e.amount);

    final Map<String, double> byCat = {};
    for (final e in list) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    }
    final catEntries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final daysCount = isCurrentMonth
        ? now.day
        : DateTime(_month.year, _month.month + 1, 0).day;
    final avgPerDay = list.isEmpty ? 0.0 : monthTotal / daysCount;

    final List<Widget> children = [];

    // Month selector
    children.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left)),
        Text('${kMonths[_month.month - 1]} ${_month.year}',
            style: Theme.of(context).textTheme.titleLarge),
        IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right)),
      ],
    ));

    // Summary card
    children.add(Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Is mahine ka total kharcha',
                style: TextStyle(color: cs.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(rupees(monthTotal),
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aaj ka',
                          style: TextStyle(
                              fontSize: 12, color: cs.onPrimaryContainer)),
                      Text(rupees(todayTotal),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Roz ka average',
                          style: TextStyle(
                              fontSize: 12, color: cs.onPrimaryContainer)),
                      Text(rupees(avgPerDay),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));

    if (list.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Is mahine koi kharcha nahi likha.\nNeeche "+ Kharcha" dabao.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ));
    } else {
      // Category breakdown
      children.add(const Padding(
        padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text('Category ke hisaab se',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ));
      for (final entry in catEntries) {
        final c = catOf(entry.key);
        final frac = monthTotal == 0 ? 0.0 : entry.value / monthTotal;
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(c.icon, size: 18, color: c.color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key)),
                  Text('${rupees(entry.value)}  (${(frac * 100).toStringAsFixed(0)}%)'),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 6,
                  color: c.color,
                  backgroundColor: c.color.withAlpha(40),
                ),
              ),
            ],
          ),
        ));
      }

      // Day-wise list
      children.add(const Padding(
        padding: EdgeInsets.fromLTRB(4, 20, 4, 4),
        child: Text('Saare kharche',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ));

      DateTime? lastDay;
      for (final e in list) {
        if (lastDay == null || !sameDay(lastDay, e.date)) {
          final dayTotal = list
              .where((x) => sameDay(x.date, e.date))
              .fold<double>(0, (s, x) => s + x.amount);
          children.add(Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
            child: Row(
              children: [
                Expanded(
                    child: Text(dayLabel(e.date),
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.w600))),
                Text(rupees(dayTotal),
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ));
          lastDay = e.date;
        }
        final c = catOf(e.category);
        children.add(Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _delete(e),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: c.color.withAlpha(40),
              child: Icon(c.icon, color: c.color),
            ),
            title: Text(e.note.isEmpty ? e.category : e.note),
            subtitle: e.note.isEmpty ? null : Text(e.category),
            trailing: Text(rupees(e.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ));
      }
      children.add(const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Tip: kharcha delete karne ke liye use left ki taraf swipe karo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ));
    }

    children.add(const SizedBox(height: 90));

    return Scaffold(
      appBar: AppBar(title: const Text('Kharcha Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: children,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Kharcha'),
      ),
    );
  }
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = kCategories.first.name;
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  void _submit() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _error = 'Sahi amount daalo');
      return;
    }
    final now = DateTime.now();
    final when = DateTime(_date.year, _date.month, _date.day, now.hour, now.minute, now.second);
    Navigator.pop(
      context,
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amt,
        category: _category,
        note: _noteCtrl.text.trim(),
        date: when,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Naya kharcha',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Kitne rupaye?',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Category'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: kCategories.map((c) {
                return ChoiceChip(
                  avatar: Icon(c.icon, size: 18, color: c.color),
                  label: Text(c.name),
                  selected: _category == c.name,
                  onSelected: (_) => setState(() => _category = c.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional) jaise "chai", "auto"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('Tareekh: ${dayLabel(_date)} (${_date.day}/${_date.month}/${_date.year})'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save karo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
