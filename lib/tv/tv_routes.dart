/// Route paths for the TV UI. `info` and `video` take route arguments.
class TvRoutes {
  TvRoutes._();

  static const home = '/tv/home';
  static const timeline = '/tv/timeline';
  static const collect = '/tv/collect';
  static const history = '/tv/history';
  static const search = '/tv/search';
  static const rules = '/tv/rules';
  static const info = '/tv/info';
  static const video = '/tv/video';

  /// Search for one tag, full screen; takes the tag name as argument.
  static const tagSearch = '/tv/tag';

  /// The phone settings pages, pushed over the shell.
  static const settings = '/settings/';
}
