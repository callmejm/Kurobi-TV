import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/core_module.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/shaders/shader_asset_service.dart';
import 'package:kazumi/services/sync/danmaku_shield_sync_service.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/pages/search/search_controller.dart';
import 'package:kazumi/pages/timeline/timeline_controller.dart';
import 'package:kazumi/tv/pages/tv_collect_page.dart';
import 'package:kazumi/tv/pages/tv_history_page.dart';
import 'package:kazumi/tv/pages/tv_home_page.dart';
import 'package:kazumi/tv/pages/tv_init_page.dart';
import 'package:kazumi/tv/pages/tv_search_page.dart';
import 'package:kazumi/tv/pages/tv_timeline_page.dart';
import 'package:kazumi/tv/tv_shell.dart';

Widget _placeholder(String label) => Center(child: Text(label));

/// Shell with the navigation rail; destination pages render in its outlet.
final tvShellModule = createModule(
  path: '/tv',
  register: (c) {
    c
      // Shell state survives destination switches, like the phone tabModule.
      ..addSingleton<PopularController>(PopularController.new)
      ..addSingleton<TimelineController>(TimelineController.new)
      ..route(
        '/',
        child: (context, state) => TvShell(
          location: state.uri.path,
          onNavigate: (path) => context.navigate(path),
          child: const RouterOutlet(),
        ),
        children: (sub) {
          sub
            ..route(
              '/home',
              child: (context, state) =>
                  TvHomePage(controller: inject<PopularController>()),
            )
            ..route(
              '/timeline',
              child: (context, state) =>
                  TvTimelinePage(controller: inject<TimelineController>()),
            )
            ..route(
              '/collect',
              child: (context, state) =>
                  TvCollectPage(controller: inject<CollectController>()),
            )
            ..route(
              '/history',
              child: (context, state) =>
                  TvHistoryPage(controller: inject<HistoryController>()),
            )
            ..route(
              '/search',
              provide: (s) =>
                  s.add<SearchPageController>(SearchPageController.new),
              child: (context, state) => TvSearchPage(
                controller: context.read<SearchPageController>(),
              ),
            )
            ..route('/rules', child: (context, state) => _placeholder('规则'));
        },
      );
  },
);

final tvModule = createModule(
  register: (c) {
    c
      ..route(
        '/',
        child: (context, state) => TvInitPage(
          pluginsController: inject<PluginsController>(),
          shaderAssetService: inject<ShaderAssetService>(),
          myController: inject<MyController>(),
          downloadController: inject<DownloadController>(),
          danmakuShieldSync: inject<DanmakuShieldSyncService>(),
        ),
        transition: TransitionType.none,
      )
      ..module(tvShellModule);
  },
);

/// Root module of the TV UI: shared app data plus TV routes.
final tvAppModule = createModule(
  register: (c) {
    c
      ..module(coreModule)
      ..module(tvModule);
  },
);
