import 'package:flutter/foundation.dart';

import '../../../data/data/expense/expense.dart';

/// Chat-local state for bubble selection and edit mode.
///
/// Selection shows the contextual app bar with edit/delete actions.
/// Editing is modal: while a transaction is being edited in the input
/// field, selecting another bubble is ignored until the edit is sent
/// or cancelled.
class ChatInteractionProvider extends ChangeNotifier {
  ExpenseData? _selected;
  ExpenseData? _editing;

  ExpenseData? get selected => _selected;
  ExpenseData? get editing => _editing;

  bool get hasSelection => _selected != null;
  bool get isEditing => _editing != null;

  /// Whether the bubble for [id] should render highlighted — true while
  /// selected and kept true while that transaction is being edited.
  bool isHighlighted(String id) => _selected?.id == id || _editing?.id == id;

  void select(ExpenseData expense) {
    if (_editing != null) return;
    if (_selected?.id == expense.id) return;
    _selected = expense;
    notifyListeners();
  }

  /// Tap behavior while a selection exists: tapping the selected bubble
  /// clears it, tapping another bubble moves the selection.
  void toggle(ExpenseData expense) {
    if (_editing != null) return;
    _selected = _selected?.id == expense.id ? null : expense;
    notifyListeners();
  }

  void clearSelection() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  void startEditing() {
    if (_selected == null) return;
    _editing = _selected;
    _selected = null;
    notifyListeners();
  }

  void cancelEditing() {
    if (_editing == null) return;
    _editing = null;
    notifyListeners();
  }

  /// Clears any state pointing at a transaction that no longer exists.
  void onExpenseDeleted(String id) {
    var changed = false;
    if (_selected?.id == id) {
      _selected = null;
      changed = true;
    }
    if (_editing?.id == id) {
      _editing = null;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
