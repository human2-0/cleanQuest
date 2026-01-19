import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config/app_config_providers.dart';
import '../../l10n/app_localizations.dart';

final appLocaleProvider = Provider<Locale>((ref) {
  final config = ref.watch(appConfigProvider);
  final systemCode =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final code = config.localeCode ?? systemCode;
  final supported = <String>{'en', 'pl'};
  return Locale(supported.contains(code) ? code : 'en');
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(appLocaleProvider);
  return lookupAppLocalizations(locale);
});
