part of restui;

enum HttpMethod {
  post,
  get,
  delete,
  put,
  patch,
  head,
}

extension HttpMethodExtension on HttpMethod {
  /// Returns [String] that represents [HttpMethod]
  ///
  /// example:
  /// ```dart
  /// HttpMethod.post.value == "POST"
  /// ```
  String get value {
    switch (this) {
      case HttpMethod.get:
        return "GET";
      case HttpMethod.post:
        return "POST";
      case HttpMethod.delete:
        return "DELETE";
      case HttpMethod.patch:
        return "PATCH";
      case HttpMethod.put:
        return "PUT";
      default:
        throw ApiException("The HTTP method provided was not recognized");
    }
  }
}

/// Represents File that can be attached to [ApiRequest] so can be sent to API
/// with [MultipartRequest]
class FileField {
  final File file;
  final String field;
  final String fileName;
  final MediaType contentType;

  const FileField({
    @required this.field,
    @required this.file,
    this.fileName,
    this.contentType,
  }) : assert(
          file != null && field != null,
          "file and field arguments cannot be null",
        );

  /// Convert FileField to multipart file
  Future<http.MultipartFile> toMultipartFile() => http.MultipartFile.fromPath(
        field,
        file.path,
        contentType: contentType,
        filename: fileName,
      );

  @override
  String toString() => <String, dynamic>{
        "file": file,
        "field": field,
        "fileName": fileName,
        "contentType": contentType,
      }.toString();
}
