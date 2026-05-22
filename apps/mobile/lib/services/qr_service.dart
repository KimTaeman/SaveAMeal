/// Handles QR code generation and scanning. No Firebase dependency.
class QrService {
  /// Returns the canonical QR payload for a given [batchId].
  ///
  /// Format: `saveameal://batch/<batchId>`
  String generateQrData(String batchId) =>
      // TODO: implement scanning via a QR package (e.g. mobile_scanner)
      'saveameal://batch/$batchId';
}
