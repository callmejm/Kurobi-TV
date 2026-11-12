import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/core_module.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/shaders/shader_asset_service.dart';
import 'package:kazumi/services/sync/danmaku_shield_sync_service.dart';
import 'package:kazumi/tv/pages/tv_init_page.dart';
import 'package:kazumi/tv/tv_routes.dart';

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
      ..route(
        TvRoutes.home,
        child: (context, state) =>
            const Scaffold(body: Center(child: Text('Kazumi TV'))),
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
