/// Returns a consistent short display ID for a batch.
/// Format: first 8 characters of the UUID (uppercased, dashes removed), with a # prefix.
/// Example: "3f2c1a7b-e5d4-..." → "#3F2C1A7B"
String formatBatchId(String batchId) {
  final clean = batchId.replaceAll('-', '').toUpperCase();
  final short = clean.substring(0, clean.length >= 8 ? 8 : clean.length);
  return '#$short';
}
