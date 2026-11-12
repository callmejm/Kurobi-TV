import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/shaders/shader_asset_service.dart';
import 'package:kazumi/services/sync/danmaku_shield_sync_service.dart';
import 'package:kazumi/tv/tv_routes.dart';

/// TV counterpart of `InitPage`: same core initialization, no dialogs or onboarding.
class TvInitPage extends StatefulWidget {
  const TvInitPage({
    super.key,
    required this.pluginsController,
    required this.shaderAssetService,
    required this.myController,
    required this.downloadController,
    required this.danmakuShieldSync,
  });

  final PluginsController pluginsController;
  final ShaderAssetService shaderAssetService;
  final MyController myController;
  final DownloadController downloadController;
  final DanmakuShieldSyncService danmakuShieldSync;

  @override
  State<TvInitPage> createState() => _TvInitPageState();
}

class _TvInitPageState extends State<TvInitPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    widget.danmakuShieldSync.start();
    unawaited(widget.shaderAssetService.copyShadersToExternalDirectory());
    unawaited(widget.myController.loadShieldList());
    try {
      await widget.downloadController.init();
    } catch (e) {
      KazumiLogger().e(
        'TvInitPage: downloadController.init() failed',
        error: e,
      );
    }
    try {
      await widget.pluginsController.init();
    } catch (error, stackTrace) {
      KazumiLogger().e(
        'TvInitPage: failed to initialize rules',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!mounted) return;
    context.navigate(TvRoutes.home);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
