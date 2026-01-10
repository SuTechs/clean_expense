import 'package:expense/data/data/expense/expense.dart';
import 'package:hive_ce/hive.dart';

import '../user/user.dart';

@GenerateAdapters([
  AdapterSpec<UserData>(),
  AdapterSpec<TransactionType>(),
  AdapterSpec<Expense>(),
])
part 'hive_adapters.g.dart';
