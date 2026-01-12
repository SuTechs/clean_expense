import 'package:hive_ce/hive.dart';

import '../expense/expense.dart';
import '../user/user.dart';

@GenerateAdapters([
  AdapterSpec<UserData>(),
  AdapterSpec<TransactionType>(),
  AdapterSpec<ExpenseData>(),
])
part 'hive_adapters.g.dart';
