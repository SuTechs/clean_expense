import 'package:flutter/material.dart';

/// Maps a category name to a rounded Material icon so each transaction bubble
/// reads at a glance, instead of every bubble of a type showing the same
/// arrow. Color stays type-/theme-driven (themes own the palette) — this is
/// purely the icon dimension.
///
/// Covers the 82 default categories in ExpenseBloc; unknown/custom categories
/// fall back to a deterministic icon picked from the name so the same custom
/// category always looks the same.
class CategoryStyle {
  CategoryStyle._();

  static const _icons = <String, IconData>{
    // Expense
    'food': Icons.restaurant_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'travel': Icons.flight_rounded,
    'transport': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'rent': Icons.home_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'coffee': Icons.local_cafe_rounded,
    'dining': Icons.restaurant_menu_rounded,
    'snacks': Icons.bakery_dining_rounded,
    'entertainment': Icons.celebration_rounded,
    'health': Icons.favorite_rounded,
    'utilities': Icons.bolt_rounded,
    'subscriptions': Icons.autorenew_rounded,
    'clothing': Icons.checkroom_rounded,
    'movies': Icons.movie_rounded,
    'medicine': Icons.medication_rounded,
    'phone': Icons.smartphone_rounded,
    'internet': Icons.wifi_rounded,
    'fitness': Icons.fitness_center_rounded,
    'gym': Icons.sports_gymnastics_rounded,
    'education': Icons.school_rounded,
    'personal': Icons.person_rounded,
    'beauty': Icons.spa_rounded,
    'electronics': Icons.devices_rounded,
    'games': Icons.sports_esports_rounded,
    'streaming': Icons.live_tv_rounded,
    'gifts': Icons.card_giftcard_rounded,
    'household': Icons.cleaning_services_rounded,
    'parking': Icons.local_parking_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'books': Icons.menu_book_rounded,
    'courses': Icons.cast_for_education_rounded,
    'vacation': Icons.beach_access_rounded,
    'insurance': Icons.shield_rounded,
    'repairs': Icons.build_rounded,
    'maintenance': Icons.handyman_rounded,
    'donations': Icons.volunteer_activism_rounded,
    'pets': Icons.pets_rounded,
    'kids': Icons.child_care_rounded,
    'family': Icons.family_restroom_rounded,
    'taxes': Icons.account_balance_rounded,
    'fees': Icons.request_quote_rounded,
    'alcohol': Icons.local_bar_rounded,
    // Income
    'salary': Icons.work_rounded,
    'bonus': Icons.emoji_events_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'consulting': Icons.support_agent_rounded,
    'commission': Icons.percent_rounded,
    'tips': Icons.savings_rounded,
    'refund': Icons.replay_rounded,
    'cashback': Icons.currency_exchange_rounded,
    'gift': Icons.redeem_rounded,
    'dividend': Icons.pie_chart_rounded,
    'interest': Icons.trending_up_rounded,
    'rental': Icons.apartment_rounded,
    'royalty': Icons.workspace_premium_rounded,
    'sales': Icons.sell_rounded,
    'reimbursement': Icons.receipt_rounded,
    'allowance': Icons.wallet_rounded,
    'pension': Icons.elderly_rounded,
    'lottery': Icons.confirmation_num_rounded,
    // Investment
    'stocks': Icons.trending_up_rounded,
    'crypto': Icons.currency_bitcoin_rounded,
    'mutual': Icons.donut_large_rounded,
    'bonds': Icons.description_rounded,
    'gold': Icons.diamond_rounded,
    'silver': Icons.brightness_7_rounded,
    'property': Icons.location_city_rounded,
    'realestate': Icons.maps_home_work_rounded,
    'ppf': Icons.account_balance_rounded,
    'nps': Icons.elderly_rounded,
    'fd': Icons.lock_clock_rounded,
    'rd': Icons.event_repeat_rounded,
    'sip': Icons.calendar_month_rounded,
    'etf': Icons.bar_chart_rounded,
    'futures': Icons.schedule_rounded,
    'options': Icons.alt_route_rounded,
    'commodities': Icons.grain_rounded,
    'retirement': Icons.beach_access_rounded,
    'savings': Icons.savings_rounded,
  };

  /// Generic icons for unknown/custom categories. Index chosen by a stable
  /// hash of the name so a given custom category is always the same icon.
  static const _fallbacks = <IconData>[
    Icons.label_rounded,
    Icons.category_rounded,
    Icons.sell_rounded,
    Icons.bookmark_rounded,
    Icons.local_offer_rounded,
    Icons.toll_rounded,
    Icons.interests_rounded,
    Icons.style_rounded,
  ];

  static IconData iconFor(String category) {
    final key = category.trim().toLowerCase();
    final known = _icons[key];
    if (known != null) return known;

    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash + unit) % _fallbacks.length;
    }
    return _fallbacks[hash];
  }
}
