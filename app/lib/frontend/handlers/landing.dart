// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;

import '../../package/search_adapter.dart';
import '../../search/search_service.dart' show SearchOrder;
import '../../service/youtube/backend.dart';
import '../../shared/handlers.dart';
import '../../shared/redis_cache.dart' show cache;
import '../../shared/tags.dart';
import '../../shared/urls.dart' as urls;

import '../request_context.dart';
import '../templates/landing.dart';

/// Handles requests for /dart
Future<shelf.Response> dartLandingHandler(shelf.Request request) async =>
    redirectResponse(urls.searchUrl(sdk: SdkTagValue.dart));

/// Handles requests for /flutter
Future<shelf.Response> flutterLandingHandler(shelf.Request request) async {
  return redirectResponse(urls.searchUrl(sdk: SdkTagValue.flutter));
}

/// Handles requests for /web
Future<shelf.Response> webLandingHandler(shelf.Request request) async {
  return redirectResponse(
    urls.searchUrl(
      sdk: SdkTagValue.dart,
      runtimes: [DartSdkRuntime.web],
    ),
  );
}

/// Handles requests for /
Future<shelf.Response> indexLandingHandler(shelf.Request request) async {
  final String? queryText = request.requestedUri.queryParameters['q']?.trim();
  if (queryText != null) {
    final String path = request.requestedUri.path;
    final String separator = path.endsWith('/') ? '' : '/';
    final String newPath = '$path${separator}packages';
    return redirectResponse(
        request.requestedUri.replace(path: newPath).toString());
  }

  Future<String> _render() async {
    final ffPackages = await searchAdapter.topFeatured(
      requiredTags: [PackageTags.isFlutterFavorite],
      count: 4,
    );

    final mostPopularPackages =
        await searchAdapter.topFeatured(order: SearchOrder.popularity);

    final topFlutterPackages =
        await searchAdapter.topFeatured(requiredTags: [SdkTag.sdkFlutter]);

    final topDartPackages =
        await searchAdapter.topFeatured(requiredTags: [SdkTag.sdkDart]);

    final topPoWVideos = youtubeBackend.getTopPackageOfWeekVideos(count: 4);

    return renderLandingPage(
      ffPackages: ffPackages,
      mostPopularPackages: mostPopularPackages,
      topFlutterPackages: topFlutterPackages,
      topDartPackages: topDartPackages,
      topPoWVideos: topPoWVideos,
    );
  }

  if (requestContext.uiCacheEnabled) {
    return htmlResponse((await cache.uiIndexPage().get(_render))!);
  }
  return htmlResponse(await _render());
}
