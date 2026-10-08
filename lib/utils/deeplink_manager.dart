import 'dart:developer';

import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/data/repositories/project_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/foundation.dart';

class DeepLinkManager {
  static const MethodChannel _channel = MethodChannel(
    'app.channel.shared.data',
  );
  static const EventChannel _eventChannel = EventChannel(
    'app.channel.shared.data/link',
  );

  static bool _isInitialLinkHandled = false;
  static StreamSubscription<dynamic>? _deepLinkSubscription;
  static String? _pendingInitialLink;
  static final Set<String> _processingLinks = <String>{};
  static bool _shouldBlockSplashNavigation = false;

  // Getter to check if splash navigation should be blocked due to deep link
  static bool get shouldBlockSplashNavigation => _shouldBlockSplashNavigation;

  // Cache for data to avoid duplicate API calls
  static final Map<String, dynamic> _propertyCache = <String, dynamic>{};
  static final Map<String, dynamic> _projectCache = <String, dynamic>{};
  static final Map<String, dynamic> _agentCache = <String, dynamic>{};
  static final Map<String, dynamic> _articleCache = <String, dynamic>{};
  // static const Duration _cacheTimeout = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};

  static Future<void> initDeepLinks(BuildContext context) async {
    // Handle initial link
    await _handleInitialLink(context);

    // Listen for subsequent deep links
    await _setupDeepLinkListener(context);
  }

  static Future<void> _handleInitialLink(BuildContext context) async {
    try {
      final initialLink = await _getInitialLink();

      if (initialLink != null && initialLink.isNotEmpty) {
        _pendingInitialLink = initialLink;
        _shouldBlockSplashNavigation = true; // Block splash navigation

        // If navigator is ready, handle immediately
        if (Constant.navigatorKey.currentState != null &&
            !_isInitialLinkHandled) {
          await _handlePendingInitialLink(context);
        } else {
          // Wait for navigator to be ready
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _handlePendingInitialLink(context);
          });
        }
      }
    } on Exception catch (e) {
      _logError('Error getting initial deep link: $e');
      _shouldBlockSplashNavigation = false; // Unblock on error
    }
  }

  static Future<void> _handlePendingInitialLink(BuildContext context) async {
    if (_pendingInitialLink != null && !_isInitialLinkHandled) {
      _isInitialLinkHandled = true;
      final uri = Uri.tryParse(_pendingInitialLink ?? '');
      if (uri != null) {
        // Wait for splash screen to complete its navigation first
        // This ensures deep link pushes on top of the main screen, not splash
        await _waitForSplashToComplete();
        if (Constant.navigatorKey.currentState != null) {
          await handleDeepLinks(context, uri, _extractSlugFromUri(uri));
        }
      }
      _pendingInitialLink = null;
      _shouldBlockSplashNavigation = false;
    }
  }

  static Future<void> _waitForSplashToComplete() async {
    // Wait for the splash screen to complete navigation
    // Check current route every 100ms, max wait 3 seconds
    var attempts = 0;
    const maxAttempts = 30; // 3 seconds total

    while (attempts < maxAttempts) {
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final currentContext = Constant.navigatorKey.currentContext;
      if (currentContext != null) {
        final currentRoute = ModalRoute.of(currentContext)?.settings.name;
        // If we're no longer on splash, splash navigation completed
        if (currentRoute != null && currentRoute != Routes.splash) {
          // Wait a bit more for the navigation animation to complete
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return;
        }
      }
      attempts++;
    }

    // Fallback: if we couldn't detect route change, wait a reasonable time
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  static Future<String?> _getInitialLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } on PlatformException catch (e) {
      _logError('Failed to get initial link: ${e.message}');
      return null;
    }
  }

  static Future<void> _setupDeepLinkListener(BuildContext context) async {
    // Cancel any existing subscription
    await _deepLinkSubscription?.cancel();

    // Listen to new links
    _deepLinkSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) async {
        final link = event.toString().trim();
        if (link.isNotEmpty) {
          final uri = Uri.tryParse(link);
          if (uri != null) {
            await handleDeepLinks(context, uri, _extractSlugFromUri(uri));
          }
        }
      },
      onError: (Object error) {
        _logError('Error receiving deep link: $error');
      },
    );
  }

  static String? _extractSlugFromUri(Uri uri) {
    // Use the last non-empty path segment as slug, ignoring query params and trailing slashes
    final nonEmptySegments = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    if (nonEmptySegments.isEmpty) return null;
    final candidate = nonEmptySegments.last.trim();
    return candidate.isEmpty ? null : candidate;
  }

  static Future<void> handleDeepLinks(
    BuildContext context,
    Uri? uri,
    String? slug,
  ) async {
    if (uri == null || slug == null || slug.isEmpty) {
      return;
    }

    // Prevent duplicate processing
    final linkKey = uri.toString();
    if (_processingLinks.contains(linkKey)) {
      return;
    }
    _processingLinks.add(linkKey);

    try {
      if (uri.path.contains('/property-details/')) {
        await _handlePropertyDeepLink(context, slug);
      } else if (uri.path.contains('/project-details/')) {
        await _handleProjectDeepLink(context, slug);
      } else if (uri.path.contains('/agent-details/')) {
        await _handleAgentDeepLink(context, slug);
      } else if (uri.path.contains('/article-details/')) {
        await _handleArticleDeepLink(context, slug);
      }
      // Add other deep link handlers here
    } finally {
      _processingLinks.remove(linkKey);
    }
  }

  static Future<void> _handlePropertyDeepLink(
    BuildContext context,
    String slug,
  ) async {
    try {
      // Use navigator context to ensure Material localizations are available
      final navContext = Constant.navigatorKey.currentContext;

      // Only show loader if navigator is ready
      if (Constant.navigatorKey.currentState != null && navContext != null) {
        unawaited(Widgets.showLoader(navContext));
      }

      final propertyData = await PropertyRepository().fetchBySlug(slug);

      // Navigate using post frame callback to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext == null) return;

        Widgets.hideLoader(navContext);
        await _navigateToPropertyDetails(propertyData);
      });
    } on Exception catch (e, st) {
      _logError('Error handling property deeplink: $e $st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext != null) {
          Widgets.hideLoader(navContext);
          HelperUtils.showSnackBarMessage(
            navContext,
            'Failed to load property details',
            type: .error,
          );
        }
      });
    }
  }

  static Future<void> _handleProjectDeepLink(
    BuildContext context,
    String slug,
  ) async {
    try {
      // Use navigator context to ensure Material localizations are available
      final navContext = Constant.navigatorKey.currentContext;

      // Only show loader if navigator is ready
      if (Constant.navigatorKey.currentState != null && navContext != null) {
        unawaited(Widgets.showLoader(navContext));
      }

      final projectData = await ProjectRepository().fetchBySlug(slug);

      // Navigate using post frame callback to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext == null) return;

        Widgets.hideLoader(navContext);
        await _navigateToProjectDetails(projectData);
      });
    } on Exception catch (e, st) {
      _logError('Error handling project deeplink: $e $st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext != null) {
          Widgets.hideLoader(navContext);
          HelperUtils.showSnackBarMessage(
            navContext,
            'Failed to load project details',
            type: .error,
          );
        }
      });
    }
  }

  static Future<void> _handleAgentDeepLink(
    BuildContext context,
    String slug,
  ) async {
    try {
      // Use navigator context to ensure Material localizations are available
      final navContext = Constant.navigatorKey.currentContext;

      // Only show loader if navigator is ready
      if (Constant.navigatorKey.currentState != null && navContext != null) {
        unawaited(Widgets.showLoader(navContext));
      }

      final agentInfo = await AgentsRepository().fetchBySlug(slug);

      // Navigate using post frame callback to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext != null) {
          Widgets.hideLoader(navContext);
          await _navigateToAgentDetails(
            agentId: agentInfo.agentId,
            isAdmin: agentInfo.isAdmin,
          );
        }
      });
    } on Exception catch (e, st) {
      _logError('Error handling agent deeplink: $e $st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext != null) {
          Widgets.hideLoader(navContext);
          HelperUtils.showSnackBarMessage(
            navContext,
            'Failed to load agent details',
            type: .error,
          );
        }
      });
    }
  }

  static Future<void> _handleArticleDeepLink(
    BuildContext context,
    String slug,
  ) async {
    try {
      await _navigateToArticleDetails(slug);
    } on Exception catch (e, st) {
      _logError('Error handling article deeplink: $e $st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = Constant.navigatorKey.currentContext;
        if (navContext != null) {
          Widgets.hideLoader(navContext);
          HelperUtils.showSnackBarMessage(
            navContext,
            'Failed to load article details',
            type: .error,
          );
        }
      });
    }
  }

  static Future<void> _navigateToPropertyDetails(
    PropertyModel propertyData,
  ) async {
    await HelperUtils.navigateToPropertyDetails(
      property: propertyData,
      popCurrentIfAlreadyOpen: true,
    );
  }

  static Future<void> _navigateToProjectDetails(
    ProjectModel projectData,
  ) async {
    await HelperUtils.navigateToProjectDetails(
      project: projectData,
      popCurrentIfAlreadyOpen: true,
    );
  }

  static Future<void> _navigateToAgentDetails({
    required String agentId,
    required bool isAdmin,
  }) async {
    final navigatorState = Constant.navigatorKey.currentState;
    final context = Constant.navigatorKey.currentContext;

    if (navigatorState != null && context != null) {
      await HelperUtils.navigateToAgentDetails(
        context: context,
        agentId: agentId,
        isAdmin: isAdmin,
        popCurrentIfAlreadyOpen: true,
      );
    }
  }

  static Future<void> _navigateToArticleDetails(String slug) async {
    final context = Constant.navigatorKey.currentContext;

    if (context != null) {
      await HelperUtils.navigateToArticleDetails(
        context: context,
        slug: slug,
        popCurrentIfAlreadyOpen: true,
      );
    }
  }

  static void _logError(String message) {
    if (kDebugMode) {
      log(message, name: 'DeepLinkManager');
    }
  }

  static void clearCache() {
    _propertyCache.clear();
    _projectCache.clear();
    _agentCache.clear();
    _articleCache.clear();
    _cacheTimestamps.clear();
  }

  static void dispose() {
    unawaited(_deepLinkSubscription?.cancel());
    _deepLinkSubscription = null;
    _processingLinks.clear();
    clearCache();
    _isInitialLinkHandled = false;
    _pendingInitialLink = null;
    _shouldBlockSplashNavigation = false;
  }
}
