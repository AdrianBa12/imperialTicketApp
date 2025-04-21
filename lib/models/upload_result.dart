class UploadResult {
  final bool success;
  final String? imageUrl;
  final String? mediaId;
  final String? errorMessage;

  UploadResult({
    required this.success,
    this.imageUrl,
    this.mediaId,
    this.errorMessage,
  });
}