import '../data/insight/insight.dart';
import 'abstract.dart';

/// Holds the "your money" insight feed shown interleaved in the chat thread.
/// In-memory mirror of the persisted JSON feed (see InsightCommand).
class InsightBloc extends AbstractBloc {
  List<InsightData> _feed = const [];

  List<InsightData> get feed => _feed;

  void setFeed(List<InsightData> feed) => notify(() => _feed = feed);
}
