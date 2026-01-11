import 'package:flutter/material.dart';

import '../../theme.dart';
import 'components/balance_card.dart';
import 'components/home_app_bar.dart';
import 'components/spending_summary.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: HomeAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),
            BalanceCard(),
            SizedBox(height: 8),
            SpendingSummary(),
            SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }
}
