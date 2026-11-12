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
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/pages/route_error_page.dart';
import 'package:kazumi/pages/settings/settings_module.dart';
import 'package:kazumi/pages/player/player_controller.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/tv/player/tv_player_page.dart';
import 'package:kazumi/tv/pages/tv_info_page.dart';
import 'package:kazumi/tv/pages/tv_rules_page.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/tv_shell_route.dart';

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
        child: (context, state) => TvShellRoute(location: state.uri.path),
        children: (sub) {
          sub
            ..route(
              '/home',
              child: (context, state) => TvHomePage(
                controller: inject<PopularController>(),
                historyController: inject<HistoryController>(),
              ),
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
            ..route(
              '/rules',
              child: (context, state) =>
                  TvRulesPage(controller: inject<PluginsController>()),
            );
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
      ..module(tvShellModule)
      // Phone settings pages; their Material controls take D-pad focus.
      ..module(settingsModule)
      ..route(
        TvRoutes.video,
        provide: (s) => s
          ..add<VideoPageController>(VideoPageController.new)
          ..add<PlayerController>(PlayerController.new),
        child: (context, state) {
          final data = state.arguments;
          final request = data is TvPlaybackRequest ? data : null;
          final args = request?.args ?? data;
          if (args is! VideoPlaybackArgs) {
            return const RouteErrorPage(message: '播放参数无效，请返回后重试。');
          }
          return TvPlayerPage(
            args: args,
            startEpisode: request?.episode,
            startRoad: request?.road ?? 0,
            playerController: context.read<PlayerController>(),
            videoPageController: context.read<VideoPageController>(),
            historyController: inject<HistoryController>(),
          );
        },
      )
      ..route(
        TvRoutes.tagSearch,
        provide: (s) => s.add<SearchPageController>(SearchPageController.new),
        child: (context, state) => Scaffold(
          body: TvSearchPage(
            controller: context.read<SearchPageController>(),
            initialQuery: 'tag:${state.arguments}',
          ),
        ),
      )
      ..route(
        TvRoutes.info,
        provide: (s) => s.add<InfoController>(InfoController.new),
        child: (context, state) {
          final item = state.arguments;
          if (item is! BangumiItem) {
            return const RouteErrorPage(message: '番剧参数无效，请返回后重试。');
          }
          return TvInfoPage(
            bangumiItem: item,
            infoController: context.read<InfoController>(),
            pluginsController: inject<PluginsController>(),
            collectController: inject<CollectController>(),
            historyController: inject<HistoryController>(),
          );
        },
      );
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
