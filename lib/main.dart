import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FinanceProvider()..loadInitialData(),
      child: const MasrofyApp(),
    ),
  );
}

// ==========================================
// 1. MODELS
// ==========================================

class DebtItem {
  String id;
  String name;
  String type; // 'دين عليك' أو 'دين لك'
  double totalAmount;
  double paidAmount;
  bool isDone;

  DebtItem({
    required this.id,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    this.isDone = false,
  });

  double get remainingAmount => max(0, totalAmount - paidAmount);
}

class TransactionItem {
  String id;
  String title;
  double amount;
  String type; // 'income' أو 'expense'
  String category;
  DateTime date;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });
}

class InvestmentIdea {
  final String id;
  final String title;
  final String risk;
  final Color riskColor;
  final String description;
  final IconData icon;

  InvestmentIdea({
    required this.id,
    required this.title,
    required this.risk,
    required this.riskColor,
    required this.description,
    required this.icon,
  });
}

// ==========================================
// 2. FINANCE PROVIDER
// ==========================================

class FinanceProvider extends ChangeNotifier {
  double _nominalBalance = 10650.0;
  double _inflationRate = 12.0;
  double _investPercentage = 30.0;

  String _selectedCurrency = 'ج.م';
  String _selectedLanguage = 'العربية';
  bool _isBiometricEnabled = false;
  bool _isNotificationsEnabled = true;

  final List<DebtItem> _debts = [];
  final List<TransactionItem> _monthlyTransactions = [];
  final DateTime _selectedMonth = DateTime.now();

  double get nominalBalance => _nominalBalance;
  double get inflationRate => _inflationRate;
  double get investPercentage => _investPercentage;
  String get selectedCurrency => _selectedCurrency;
  String get selectedLanguage => _selectedLanguage;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  List<DebtItem> get debts => List.unmodifiable(_debts);
  List<TransactionItem> get monthlyTransactions => List.unmodifiable(_monthlyTransactions);
  DateTime get selectedMonth => _selectedMonth;

  final List<InvestmentIdea> investmentIdeas = [
    InvestmentIdea(
      id: '1',
      title: 'صناديق الذهب والادخار',
      risk: 'مخاطرة منخفضة',
      riskColor: Colors.green,
      description: 'شراء وثائق في صناديق استثمار بالذهب للحفاظ على القوة الشرائية وتحقيق نمو آمن.',
      icon: Icons.savings_rounded,
    ),
    InvestmentIdea(
      id: '2',
      title: 'صناديق الأسهم والمؤشرات',
      risk: 'مخاطرة متوسطة',
      riskColor: Colors.orange,
      description: 'الاستثمار في وثائق صناديق الأسهم المحلية لتحقيق عائد أعلى متغلب على التضخم.',
      icon: Icons.show_chart_rounded,
    ),
  ];

  double get totalMonthlyIncome => _monthlyTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalMonthlyExpense => _monthlyTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get monthlyNetBalance => totalMonthlyIncome - totalMonthlyExpense;

  double get remainingDebts => _debts
      .where((d) => d.type == 'دين عليك' && !d.isDone)
      .fold(0.0, (sum, item) => sum + item.remainingAmount);

  double get netAvailableBalance => max(0, _nominalBalance - remainingDebts);
  double get realPurchasingPower => _nominalBalance / pow(1 + (_inflationRate / 100), 1.0);
  double get purchasingPowerLoss => _nominalBalance - realPurchasingPower;

  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryMap = {};
    for (var t in _monthlyTransactions.where((t) => t.type == 'expense')) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0.0) + t.amount;
    }
    return categoryMap;
  }

  void loadInitialData() {
    _debts.addAll([
      DebtItem(id: '1', name: 'أحمد', type: 'دين عليك', totalAmount: 2000, paidAmount: 500),
      DebtItem(id: '2', name: 'محمد', type: 'دين لك', totalAmount: 1500, paidAmount: 1500, isDone: true),
    ]);

    _monthlyTransactions.addAll([
      TransactionItem(id: '1', title: 'راتب شهري', amount: 8000, type: 'income', category: 'راتب', date: DateTime.now()),
      TransactionItem(id: '2', title: 'شراء مستلزمات', amount: 1200, type: 'expense', category: 'طعام', date: DateTime.now()),
    ]);
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    _nominalBalance = newBalance;
    notifyListeners();
  }

  void setInflationRate(double rate) {
    _inflationRate = rate;
    notifyListeners();
  }

  void setInvestPercentage(double percentage) {
    _investPercentage = percentage;
    notifyListeners();
  }

  void setTotalIncomeDirectly(double newTotalIncome) {
    final index = _monthlyTransactions.indexWhere((t) => t.type == 'income');
    if (index != -1) {
      _monthlyTransactions[index].amount = newTotalIncome;
    } else {
      _monthlyTransactions.add(
        TransactionItem(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'دخل رئيسي', amount: newTotalIncome, type: 'income', category: 'راتب', date: DateTime.now()),
      );
    }
    notifyListeners();
  }

  void setTotalExpenseDirectly(double newTotalExpense) {
    final index = _monthlyTransactions.indexWhere((t) => t.type == 'expense');
    if (index != -1) {
      _monthlyTransactions[index].amount = newTotalExpense;
    } else {
      _monthlyTransactions.add(
        TransactionItem(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'مصروف رئيسي', amount: newTotalExpense, type: 'expense', category: 'أخرى', date: DateTime.now()),
      );
    }
    notifyListeners();
  }

  void addTransaction(TransactionItem transaction) {
    _monthlyTransactions.insert(0, transaction);
    notifyListeners();
  }

  void updateTransaction(String id, String newTitle, double newAmount, String newType, String newCategory) {
    final index = _monthlyTransactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _monthlyTransactions[index].title = newTitle;
      _monthlyTransactions[index].amount = newAmount;
      _monthlyTransactions[index].type = newType;
      _monthlyTransactions[index].category = newCategory;
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _monthlyTransactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void addDebt(DebtItem debt) {
    _debts.add(debt);
    notifyListeners();
  }

  void updateDebt(String id, String newName, String newType, double newTotal, double newPaid) {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _debts[index].name = newName;
      _debts[index].type = newType;
      _debts[index].totalAmount = newTotal;
      _debts[index].paidAmount = newPaid;
      _debts[index].isDone = newPaid >= newTotal;
      notifyListeners();
    }
  }

  void deleteDebt(String id) {
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void setCurrency(String currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void toggleBiometric(bool value) {
    _isBiometricEnabled = value;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _isNotificationsEnabled = value;
    notifyListeners();
  }
}

// ==========================================
// 3. UI SCREENS
// ==========================================

class MasrofyApp extends StatelessWidget {
  const MasrofyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مصروفي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardTab(),
    MonthlyReportTab(),
    InvestmentsTab(),
    DebtsTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'التقرير'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'الاستثمار'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'الديون'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  void _showEditBalanceDialog(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    final controller = TextEditingController(text: provider.nominalBalance.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الرصيد الإجمالي'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'الرصيد', suffixText: provider.selectedCurrency),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) {
                  provider.updateBalance(val);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditIncomeExpenseDialog(BuildContext context, bool isIncome) {
    final provider = context.read<FinanceProvider>();
    final initialVal = isIncome ? provider.totalMonthlyIncome : provider.totalMonthlyExpense;
    final controller = TextEditingController(text: initialVal.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(isIncome ? 'تعديل إجمالي الدخل' : 'تعديل إجمالي المصروفات'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'المبلغ', suffixText: provider.selectedCurrency),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) {
                  if (isIncome) {
                    provider.setTotalIncomeDirectly(val);
                  } else {
                    provider.setTotalExpenseDirectly(val);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مصروفي - اللوحة الرئيسية'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(context, provider),
            const SizedBox(height: 16),
            _buildInflationCard(context, provider),
            const SizedBox(height: 16),
            _buildQuickStats(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.teal, Color(0xFF004D40)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const Text('إجمالي الرصيد الرقمي (الاسمي)', style: TextStyle(color: Colors.white70, fontSize: 15)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                onPressed: () => _showEditBalanceDialog(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.nominalBalance.toStringAsFixed(0)} ${provider.selectedCurrency}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInflationCard(BuildContext context, FinanceProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down_rounded, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text('تحليل القوة الشرائية بعد التضخم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('القوة الشرائية الحقيقية:'),
                Text(
                  '${provider.realPurchasingPower.toStringAsFixed(0)} ${provider.selectedCurrency}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تأكل القوة الشرائية (الخسارة):'),
                Text(
                  '-${provider.purchasingPowerLoss.toStringAsFixed(0)} ${provider.selectedCurrency}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('معدل التضخم: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: provider.inflationRate,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    label: '${provider.inflationRate.round()}%',
                    onChanged: (val) => provider.setInflationRate(val),
                  ),
                ),
                Text('${provider.inflationRate.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, FinanceProvider provider) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showEditIncomeExpenseDialog(context, true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('الدخل الشهري', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${provider.totalMonthlyIncome.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _showEditIncomeExpenseDialog(context, false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('المصروفات الشهرية', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${provider.totalMonthlyExpense.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MonthlyReportTab extends StatelessWidget {
  const MonthlyReportTab({super.key});

  void _showEditTransactionDialog(BuildContext context, TransactionItem item) {
    final provider = context.read<FinanceProvider>();
    final titleController = TextEditingController(text: item.title);
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(0));
    String type = item.type;
    String category = item.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل المعاملة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'الوصف')),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ', suffixText: provider.selectedCurrency)),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('مصروف (-)')),
                    DropdownMenuItem(value: 'income', child: Text('دخل (+)')),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: ['طعام', 'مواصلات', 'فواتير', 'راتب', 'تسوق', 'أخرى']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.deleteTransaction(item.id);
                  Navigator.pop(ctx);
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (titleController.text.isNotEmpty && amount != null) {
                    provider.updateTransaction(item.id, titleController.text, amount, type, category);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير شهر ${provider.selectedMonth.month}/${provider.selectedMonth.year}'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('إجمالي الدخل', '${provider.totalMonthlyIncome.toStringAsFixed(0)} ${provider.selectedCurrency}', Colors.green),
                        const SizedBox(height: 30, child: VerticalDivider()),
                        _buildStatColumn('إجمالي المصروفات', '${provider.totalMonthlyExpense.toStringAsFixed(0)} ${provider.selectedCurrency}', Colors.red),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الشهر (الفائض/العجز):', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${provider.monthlyNetBalance.toStringAsFixed(0)} ${provider.selectedCurrency}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: provider.monthlyNetBalance >= 0 ? Colors.teal : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('توزيع المصروفات حسب الفئة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...provider.expensesByCategory.entries.map((entry) {
              double percentage = provider.totalMonthlyExpense > 0 ? (entry.value / provider.totalMonthlyExpense) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value.toStringAsFixed(0)} ${provider.selectedCurrency} (${(percentage * 100).toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: percentage, color: Colors.teal, backgroundColor: Colors.teal.shade50),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            const Text('سجل المعاملات اليومية (اضغط للتعديل)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.monthlyTransactions.length,
              itemBuilder: (ctx, index) {
                final item = provider.monthlyTransactions[index];
                final isIncome = item.type == 'income';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _showEditTransactionDialog(context, item),
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? Colors.green : Colors.red),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.category} • ${item.date.day}/${item.date.month}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}${item.amount.toStringAsFixed(0)} ${provider.selectedCurrency}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'طعام';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة معاملة جديدة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'الوصف (مثال: غداء)')),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ', suffixText: provider.selectedCurrency)),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('مصروف (-)')),
                    DropdownMenuItem(value: 'income', child: Text('دخل (+)')),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                ),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  items: ['طعام', 'مواصلات', 'فواتير', 'راتب', 'تسوق', 'أخرى']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (titleController.text.isNotEmpty && amount != null) {
                    final item = TransactionItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      amount: amount,
                      type: type,
                      category: category,
                      date: DateTime.now(),
                    );
                    context.read<FinanceProvider>().addTransaction(item);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvestmentsTab extends StatefulWidget {
  const InvestmentsTab({super.key});

  @override
  State<InvestmentsTab> createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends State<InvestmentsTab> {
  double _expectedReturnRate = 15.0;
  double _investYears = 5.0;

  final _targetSavingController = TextEditingController(text: '50000');
  double _savingMonths = 12.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    double investAmount = provider.netAvailableBalance * (provider.investPercentage / 100);

    double futureInvestmentValue = investAmount * pow((1 + (_expectedReturnRate / 100)), _investYears);

    double targetGoal = double.tryParse(_targetSavingController.text) ?? 50000;
    double requiredMonthlySaving = targetGoal / _savingMonths;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاستثمار والادخار والحاسبة'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الرصيد المتاح للاستثمار/الادخار:'),
                      Text('${provider.netAvailableBalance.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المبلغ المستثمر (${provider.investPercentage.round()}%):'),
                      Text('${investAmount.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: provider.investPercentage,
                    min: 5.0,
                    max: 100.0,
                    divisions: 19,
                    onChanged: (val) => provider.setInvestPercentage(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('حاسبة النمو المتوقع للاستثمار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Text('العائد السنوي المتوقع: ${_expectedReturnRate.round()}%'),
                  Slider(
                    value: _expectedReturnRate,
                    min: 1.0,
                    max: 40.0,
                    divisions: 39,
                    onChanged: (v) => setState(() => _expectedReturnRate = v),
                  ),
                  Text('مدة الاستثمار: ${_investYears.round()} سنوات'),
                  Slider(
                    value: _investYears,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    onChanged: (v) => setState(() => _investYears = v),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('القيمة المتوقعة مستقبلاً:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${futureInvestmentValue.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.savings_outlined, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('حاسبة خطة هدف الادخار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: _targetSavingController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'المبلغ المستهدف للوصول إليه', suffixText: provider.selectedCurrency),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text('مدة التجميع: ${_savingMonths.round()} شهور'),
                  Slider(
                    value: _savingMonths,
                    min: 1.0,
                    max: 60.0,
                    divisions: 59,
                    onChanged: (v) => setState(() => _savingMonths = v),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المطلوب ادخاره شهرياً:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${requiredMonthlySaving.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('الفرص الاستثمارية المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...provider.investmentIdeas.map((idea) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: Icon(idea.icon, color: Colors.teal)),
                  title: Text(idea.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(idea.description),
                  trailing: Chip(label: Text(idea.risk, style: const TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: idea.riskColor),
                ),
              )),
        ],
      ),
    );
  }
}

class DebtsTab extends StatelessWidget {
  const DebtsTab({super.key});

  void _showDebtDialog(BuildContext context, {DebtItem? existingDebt}) {
    final provider = context.read<FinanceProvider>();
    final isEditing = existingDebt != null;

    final nameController = TextEditingController(text: isEditing ? existingDebt.name : '');
    final totalController = TextEditingController(text: isEditing ? existingDebt.totalAmount.toStringAsFixed(0) : '');
    final paidController = TextEditingController(text: isEditing ? existingDebt.paidAmount.toStringAsFixed(0) : '0');
    String type = isEditing ? existingDebt.type : 'دين عليك';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(isEditing ? 'تعديل الدين' : 'إضافة دين جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم (مثال: أحمد)')),
                  TextField(controller: totalController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ الإجمالي', suffixText: provider.selectedCurrency)),
                  TextField(controller: paidController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ المسدد حتى الآن', suffixText: provider.selectedCurrency)),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: type,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'دين عليك', child: Text('دين عليك (-)')),
                      DropdownMenuItem(value: 'دين لك', child: Text('دين لك (+)')),
                    ],
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () {
                    provider.deleteDebt(existingDebt.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  final total = double.tryParse(totalController.text);
                  final paid = double.tryParse(paidController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty && total != null) {
                    if (isEditing) {
                      provider.updateDebt(existingDebt.id, nameController.text, type, total, paid);
                    } else {
                      final item = DebtItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        type: type,
                        totalAmount: total,
                        paidAmount: paid,
                        isDone: paid >= total,
                      );
                      provider.addDebt(item);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الديون'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الديون القائمة عليك:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('${provider.remainingDebts.toStringAsFixed(0)} ${provider.selectedCurrency}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('اضغط على أي دين لتعديله أو تحديث سداده', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ...provider.debts.map((debt) {
            double progress = debt.totalAmount > 0 ? (debt.paidAmount / debt.totalAmount) : 0.0;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showDebtDialog(context, existingDebt: debt),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(debt.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit, size: 16, color: Colors.grey),
                            ],
                          ),
                          Chip(
                            label: Text(debt.isDone ? 'مكتمل السداد' : debt.type, style: const TextStyle(color: Colors.white)),
                            backgroundColor: debt.isDone ? Colors.grey : (debt.type == 'دين عليك' ? Colors.red : Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('المتبقي: ${debt.remainingAmount.toStringAsFixed(0)} من ${debt.totalAmount.toStringAsFixed(0)} ${provider.selectedCurrency}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: min(1.0, progress), color: debt.type == 'دين عليك' ? Colors.red : Colors.green),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showDebtDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money_rounded, color: Colors.teal),
              title: const Text('العملة'),
              subtitle: Text('العملة الحالية: ${provider.selectedCurrency}'),
              trailing: DropdownButton<String>(
                value: provider.selectedCurrency,
                underline: const SizedBox(),
                items: ['ج.م', '\$', '€', 'SAR', 'AED']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) provider.setCurrency(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: Colors.teal),
              title: const Text('اللغة / Language'),
              subtitle: Text(provider.selectedLanguage),
              trailing: DropdownButton<String>(
                value: provider.selectedLanguage,
                underline: const SizedBox(),
                items: ['العربية', 'English']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) provider.setLanguage(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded, color: Colors.teal),
              title: const Text('الدخول ببصمة الإصبع / الوجه'),
              subtitle: const Text('تأمين التطبيق بالحساسات البيومترية'),
              value: provider.isBiometricEnabled,
              onChanged: (val) => provider.toggleBiometric(val),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded, color: Colors.teal),
              title: const Text('الإشعارات والتنبيهات'),
              subtitle: const Text('تنبيهات بمواعيد سداد الديون والمصروفات'),
              value: provider.isNotificationsEnabled,
              onChanged: (val) => provider.toggleNotifications(val),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'تطبيق مصروفي v2.0 - جميع الحقوق محفوظة',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }
}