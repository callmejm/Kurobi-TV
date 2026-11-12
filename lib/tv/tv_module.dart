import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/core_module.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/shaders/shader_asset_service.dart';
import 'package:kazumi/services/sync/danmaku_shield_sync_service.dart';
import 'package:kazumi/tv/pages/tv_init_page.dart';
import 'package:kazumi/tv/tv_shell.dart';

Widget _placeholder(String label) => Center(child: Text(label));

/// Shell with the navigation rail; destination pages render in its outlet.
final tvShellModule = createModule(
  path: '/tv',
  register: (c) {
    c.route(
      '/',
      child: (context, state) => TvShell(
        location: state.uri.path,
        onNavigate: (path) => context.navigate(path),
        child: const RouterOutlet(),
      ),
      children: (sub) {
        sub
          ..route('/home', child: (context, state) => _placeholder('首页'))
          ..route('/timeline', child: (context, state) => _placeholder('时间表'))
          ..route('/collect', child: (context, state) => _placeholder('收藏'))
          ..route('/history', child: (context, state) => _placeholder('历史'))
          ..route('/search', child: (context, state) => _placeholder('搜索'))
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
