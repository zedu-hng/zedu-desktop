/// Human-readable AI credit balance, e.g. `1 AI credit`, `1,250,000 AI credits`.
///
/// Used wherever the organisation's credit balance is shown so the number has
/// thousands separators and the noun matches the count.
String formatAiCredits(int credits) {
  final grouped = credits.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final sign = credits < 0 ? '-' : '';
  final noun = credits.abs() == 1 ? 'credit' : 'credits';
  return '$sign$grouped AI $noun';
}
