// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
//import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/options.dart';
import '../l10n/localizations.dart';
import '../widgets/adaptive.dart';

import 'about.dart' as about;
import 'home.dart';
import 'settings_list_item.dart';

enum _ExpandableSetting {
  textScale,
  textDirection,
  locale,
  platform,
  theme,
}

class SettingsPage extends StatefulWidget {
  SettingsPage({this.animationController});

  final AnimationController animationController;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _ExpandableSetting _expandedSettingId;
  Animation<double> _staggerSettingsItemsAnimation;

  void onTapSetting(_ExpandableSetting settingId) {
    setState(() {
      if (_expandedSettingId == settingId) {
        _expandedSettingId = null;
      } else {
        _expandedSettingId = settingId;
      }
    });
  }

  void _closeSettingId(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _expandedSettingId = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // When closing settings, also shrink expanded setting.
    widget.animationController.addStatusListener(_closeSettingId);

    _staggerSettingsItemsAnimation = CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(
        0.5,
        1.0,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.animationController.removeStatusListener(_closeSettingId);
  }

  /// Given a [Locale], returns a [DisplayOption] with its native name for a
  /// title and its name in the currently selected locale for a subtitle. If the
  /// native name can't be determined, it is omitted. If the locale can't be
  /// determined, the locale code is used.
  DisplayOption _getLocaleDisplayOption(BuildContext context, Locale locale) {
    // TODO: gsw, fil, and es_419 aren't in flutter_localized_countries' dataset
    final localeCode = locale.toString();
    final localeName = LocaleNames.of(context).nameOf(localeCode);
    if (localeName != null) {
      final localeNativeName =
          LocaleNamesLocalizationsDelegate.nativeLocaleNames[localeCode];
      return localeNativeName != null
          ? DisplayOption(localeNativeName, subtitle: localeName)
          : DisplayOption(localeName);
    } else {
      switch (localeCode) {
        case 'gsw':
          return DisplayOption('Schwiizertüütsch', subtitle: 'Swiss German');
        case 'fil':
          return DisplayOption('Filipino', subtitle: 'Filipino');
        case 'es_419':
          return DisplayOption(
            'español (Latinoamérica)',
            subtitle: 'Spanish (Latin America)',
          );
      }
    }

    return DisplayOption(localeCode);
  }

  /// Create a sorted — by native name – map of supported locales to their
  /// intended display string, with a system option as the first element.
  LinkedHashMap<Locale, DisplayOption> _getLocaleOptions() {
    var localeOptions = LinkedHashMap.of({
      systemLocaleOption: DisplayOption(
        AsLocalizations.of(context).settingsSystemDefault +
            (deviceLocale != null
                ? ' - ${_getLocaleDisplayOption(context, deviceLocale).title}'
                : ''),
      ),
    });
    var supportedLocales =
        List<Locale>.from(AsLocalizations.supportedLocales);
    supportedLocales.removeWhere((locale) => locale == deviceLocale);

    final displayLocales = Map<Locale, DisplayOption>.fromIterable(
      supportedLocales,
      value: (dynamic locale) =>
          _getLocaleDisplayOption(context, locale as Locale),
    ).entries.toList()
      ..sort((l1, l2) => compareAsciiUpperCase(l1.value.title, l2.value.title));

    localeOptions.addAll(LinkedHashMap.fromEntries(displayLocales));
    return localeOptions;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final options = AsOptions.of(context);
    final isDesktop = isDisplayDesktop(context);

    final settingsListItems = [
      SettingsListItem<double>(
        title: AsLocalizations.of(context).settingsTextScaling,
        selectedOption: options.textScaleFactor(
          context,
          useSentinel: true,
        ),
        optionsMap: LinkedHashMap.of({
          systemTextScaleFactorOption: DisplayOption(
            AsLocalizations.of(context).settingsSystemDefault,
          ),
          0.8: DisplayOption(
            AsLocalizations.of(context).settingsTextScalingSmall,
          ),
          1.0: DisplayOption(
            AsLocalizations.of(context).settingsTextScalingNormal,
          ),
          2.0: DisplayOption(
            AsLocalizations.of(context).settingsTextScalingLarge,
          ),
          3.0: DisplayOption(
            AsLocalizations.of(context).settingsTextScalingHuge,
          ),
        }),
        onOptionChanged: (newTextScale) => AsOptions.update(
          context,
          options.copyWith(textScaleFactor: newTextScale),
        ),
        onTapSetting: () => onTapSetting(_ExpandableSetting.textScale),
        isExpanded: _expandedSettingId == _ExpandableSetting.textScale,
      ),
      SettingsListItem<CustomTextDirection>(
        title: AsLocalizations.of(context).settingsTextDirection,
        selectedOption: options.customTextDirection,
        optionsMap: LinkedHashMap.of({
          CustomTextDirection.localeBased: DisplayOption(
            AsLocalizations.of(context).settingsTextDirectionLocaleBased,
          ),
          CustomTextDirection.ltr: DisplayOption(
            AsLocalizations.of(context).settingsTextDirectionLTR,
          ),
          CustomTextDirection.rtl: DisplayOption(
            AsLocalizations.of(context).settingsTextDirectionRTL,
          ),
        }),
        onOptionChanged: (newTextDirection) => AsOptions.update(
          context,
          options.copyWith(customTextDirection: newTextDirection),
        ),
        onTapSetting: () => onTapSetting(_ExpandableSetting.textDirection),
        isExpanded: _expandedSettingId == _ExpandableSetting.textDirection,
      ),
      SettingsListItem<Locale>(
        title: AsLocalizations.of(context).settingsLocale,
        selectedOption: options.locale == deviceLocale
            ? systemLocaleOption
            : options.locale,
        optionsMap: _getLocaleOptions(),
        onOptionChanged: (newLocale) {
          if (newLocale == systemLocaleOption) {
            newLocale = deviceLocale;
          }
          AsOptions.update(
            context,
            options.copyWith(locale: newLocale),
          );
        },
        onTapSetting: () => onTapSetting(_ExpandableSetting.locale),
        isExpanded: _expandedSettingId == _ExpandableSetting.locale,
      ),
      SettingsListItem<TargetPlatform>(
        title: AsLocalizations.of(context).settingsPlatformMechanics,
        selectedOption: options.platform,
        optionsMap: LinkedHashMap.of({
          TargetPlatform.android: DisplayOption('Android'),
          TargetPlatform.iOS: DisplayOption('iOS'),
          TargetPlatform.macOS: DisplayOption('macOS'),
          TargetPlatform.linux: DisplayOption('Linux'),
          TargetPlatform.windows: DisplayOption('Windows'),
        }),
        onOptionChanged: (newPlatform) => AsOptions.update(
          context,
          options.copyWith(platform: newPlatform),
        ),
        onTapSetting: () => onTapSetting(_ExpandableSetting.platform),
        isExpanded: _expandedSettingId == _ExpandableSetting.platform,
      ),
      SettingsListItem<ThemeMode>(
        title: AsLocalizations.of(context).settingsTheme,
        selectedOption: options.themeMode,
        optionsMap: LinkedHashMap.of({
          ThemeMode.system: DisplayOption(
            AsLocalizations.of(context).settingsSystemDefault,
          ),
          ThemeMode.dark: DisplayOption(
            AsLocalizations.of(context).settingsDarkTheme,
          ),
          ThemeMode.light: DisplayOption(
            AsLocalizations.of(context).settingsLightTheme,
          ),
        }),
        onOptionChanged: (newThemeMode) => AsOptions.update(
          context,
          options.copyWith(themeMode: newThemeMode),
        ),
        onTapSetting: () => onTapSetting(_ExpandableSetting.theme),
        isExpanded: _expandedSettingId == _ExpandableSetting.theme,
      ),
      SlowMotionSetting(),
    ];

    return Material(
      color: colorScheme.secondaryVariant,
      child: Padding(
        padding: isDesktop
            ? EdgeInsets.zero
            : const EdgeInsets.only(
                bottom: asHeaderHeight,
              ),
        // Remove ListView top padding as it is already accounted for.
        child: MediaQuery.removePadding(
          removeTop: isDesktop,
          context: context,
          child: ListView(
            children: [
              if (isDesktop)
                const SizedBox(height: firstHeaderDesktopTopPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ExcludeSemantics(
                  child: Header(
                    color: Theme.of(context).colorScheme.onSurface,
                    text: AsLocalizations.of(context).settingsTitle,
                  ),
                ),
              ),
              if (isDesktop)
                ...settingsListItems
              else ...[
                _AnimateSettingsListItems(
                  animation: _staggerSettingsItemsAnimation,
                  children: settingsListItems,
                ),
                const SizedBox(height: 16),
                Divider(thickness: 2, height: 0, color: colorScheme.background),
                const SizedBox(height: 12),
                SettingsAbout(),
                const SizedBox(height: 12),
                Divider(thickness: 2, height: 0, color: colorScheme.background),
                SettingsAttribution(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsAbout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsLink(
      title: AsLocalizations.of(context).settingsAbout,
      icon: Icons.info_outline,
      onTap: () {
        about.showAboutDialog(context: context);
      },
    );
  }
}

class SettingsAttribution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    final verticalPadding = isDesktop ? 0.0 : 28.0;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isDesktop ? 24 : 32,
          end: isDesktop ? 0 : 32,
          top: verticalPadding,
          bottom: verticalPadding,
        ),
        child: Text(
          AsLocalizations.of(context).settingsAttribution,
          style: Theme.of(context).textTheme.bodyText1.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
          textAlign: isDesktop ? TextAlign.end : TextAlign.start,
        ),
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final String title;
  final IconData icon;
  final GestureTapCallback onTap;

  _SettingsLink({this.title, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = isDisplayDesktop(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 32,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.onSecondary.withOpacity(0.5),
              size: 24,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  top: 12,
                  bottom: 12,
                ),
                child: Text(
                  title,
                  style: textTheme.subtitle2.apply(
                    color: colorScheme.onSecondary,
                  ),
                  textAlign: isDesktop ? TextAlign.end : TextAlign.start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animate the settings list items to stagger in from above.
class _AnimateSettingsListItems extends StatelessWidget {
  const _AnimateSettingsListItems({
    Key key,
    this.animation,
    this.children,
    this.topPadding,
    this.bottomPadding,
  }) : super(key: key);

  final Animation<double> animation;
  final List<Widget> children;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final dividingPadding = 4.0;
    final topPaddingTween = Tween<double>(
      begin: 0,
      end: children.length * dividingPadding,
    );
    final dividerTween = Tween<double>(
      begin: 0,
      end: dividingPadding,
    );

    return Padding(
      padding: EdgeInsets.only(top: topPaddingTween.animate(animation).value),
      child: Column(
        children: [
          for (Widget child in children)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: dividerTween.animate(animation).value,
                  ),
                  child: child,
                );
              },
              child: child,
            ),
        ],
      ),
    );
  }
}
