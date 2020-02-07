import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:restui/restui.dart';

import 'example_photo_model.dart';

class ExampleApi extends ApiBase {
  _PhotoQueries _photos;
  _PhotoQueries get photos => _photos;

  ExampleApi({
    @required Uri uri,
    ApiLink link,
    Map<String, String> defaultHeaders,
  }) : super(uri: uri, defaultHeaders: defaultHeaders, link: link) {
    _photos = _PhotoQueries(this);
  }
}

class _PhotoQueries {
  ExampleApi api;
  _PhotoQueries(this.api);

  Future<ExamplePhotoModel> getRandom() async {
    final apiResponse = await api.call(
      endpoint: "/id/${Random().nextInt(50)}/info",
      method: HttpMethod.GET,
    );
    return ExamplePhotoModel.fromJson(
      json.decode(apiResponse.httpResponse.body),
    );
  }
}