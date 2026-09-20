import 'dart:ui' show Locale, PlatformDispatcher;

import '../domain/reminder_copy.dart' show ReminderTopic;
import 'strings_en.dart';
import 'strings_tr.dart';

/// The app's language: the device's own, or one the person picked in
/// "Ayarlar → Dil".
///
/// Only [system] follows the phone; the other two win over it and are
/// remembered (`nezaman.lang.v1`).
enum AppLang {
  system,
  tr,
  en;

  static AppLang fromId(String? id) =>
      AppLang.values.firstWhere((l) => l.name == id, orElse: () => AppLang.system);

  String get id => name;
}

/// Every supported language, in the order Flutter falls back through them —
/// Turkish first, so an unrelated device language lands there.
const supportedLangLocales = [Locale('tr'), Locale('en')];

Strings _strings = const TrStrings();
AppLang _lang = AppLang.system;

/// Every piece of user-visible text, read from the active language.
///
/// A plain getter rather than an inherited widget, the way [AppColor] reads
/// the selected theme: domain code (reminder bodies, date labels, the widget
/// snapshot) needs the same strings and has no `BuildContext`. Switching
/// language goes through `CardStore.setLang`, which saves it and rebuilds the
/// whole tree.
Strings get S => _strings;

/// The language the person chose — [AppLang.system] until they pick one.
AppLang get appLang => _lang;

/// The language actually in use: [appLang], or the device's when it is
/// [AppLang.system].
AppLang get resolvedLang => _strings.lang;

/// The locale to hand [MaterialApp], or `null` under [AppLang.system] so
/// Flutter resolves the device's own.
Locale? get appLocale => _lang == AppLang.system ? null : Locale(_lang.name);

/// Stands in for the platform's locale when [AppLang.system] is resolved.
///
/// The test suite pins it to Turkish (`test/flutter_test_config.dart`) so the
/// assertions read the original copy whatever language the host machine runs
/// in. Never set outside tests.
Locale? debugDeviceLocale;

/// Point [S] at [lang], resolving [AppLang.system] against the device.
///
/// [device] defaults to the platform's current locale; pass it in tests.
void applyLang(AppLang lang, {Locale? device}) {
  _lang = lang;
  final effective = switch (lang) {
    AppLang.tr => AppLang.tr,
    AppLang.en => AppLang.en,
    AppLang.system => _fromDevice(
      device ?? debugDeviceLocale ?? PlatformDispatcher.instance.locale,
    ),
  };
  _strings = effective == AppLang.en ? const EnStrings() : const TrStrings();
}

/// English for an English phone, Turkish for everything else — the same
/// fallback order as [supportedLangLocales].
AppLang _fromDevice(Locale locale) =>
    locale.languageCode.toLowerCase() == 'en' ? AppLang.en : AppLang.tr;

/// One ready-made card offered on the "Yeni kart" page, and one suggestion on
/// the empty state: `(name, glyph key, days)`.
typedef NamedCard = (String, String, int);

/// A tier's row on the "Durum renkleri" page: `(title, body, sample card)`.
typedef LegendRow = (String, String, String);

/// Every user-visible string, per language.
///
/// Members are grouped the way the screens are. Adding one here makes the
/// analyzer demand it in both [TrStrings] and [EnStrings], which is the point:
/// a language cannot silently fall behind.
abstract class Strings {
  const Strings();

  AppLang get lang;

  /// What this language calls itself, for the language picker.
  String get langName;

  // ------------------------------------------------------------------ common

  /// The store name, which is the same everywhere.
  String get appName => 'Kaç Gün Oldu?';

  /// The app's own question, as a title.
  String get appHeadline;

  String get cancel;
  String get ok;
  String get save;
  String get delete;
  String get deleteAll;
  String get back;
  String get close;
  String get undo;
  String get select;
  String get restore;

  // -------------------------------------------------------------------- date

  /// Sunday first — `dow[d.weekday % 7]`.
  List<String> get dow;
  List<String> get months;
  List<String> get monthsShort;

  /// `18 Eylül` / `September 18`, with the year when it is not this one.
  String dayMonth(int day, int month, {int? year});

  /// `18 Eylül 2026` / `September 18, 2026`.
  String fullDate(int day, int month, int year);

  /// `Eylül 2026` / `September 2026` — the timeline's month heading.
  String monthYear(int month, int year) => '${months[month - 1]} $year';

  String get relToday;
  String get relYesterday;
  String relDaysAgo(int n);
  String relWeeksAgo(int n);
  String relMonthsAgo(int n);

  // --------------------------------------------------------------- frequency

  /// The chips under "Ne sıklıkla tekrarlıyorsun?", as `(days, label)`.
  List<(int, String)> get frequencyPresets;

  /// Anything off the preset list: `10 günde bir` / `Every 10 days`.
  String everyNDays(int days);

  /// The sentence appended to a reminder when the rhythm was chosen, not
  /// learned: ` Hedefin haftada bir.` / ` Your goal: weekly.`
  String goalSuffix(String frequencyLabel);

  // ------------------------------------------------------------------ filter

  String get filterAll;
  String get filterLate;
  String get filterSoon;

  // ------------------------------------------------------- stats & card face

  /// No records at all.
  String get notMarkedYet;

  /// Recorded today — the meta line.
  String get doneTodayMeta;

  /// `18 Eylül ~7 günde bir`. The interval half never wraps.
  String metaEvery(String date, int typical);

  String get ringNew;
  String ringDays(int n);
  String get ringToday;
  String ringOver(int n);

  /// The suffix [ringDays] and [ringOver] end with, so the ring can split the
  /// number from its unit.
  String get ringUnitSuffix;

  /// The unit on its own line inside the ring.
  String get ringUnit;

  /// The third line inside the ring: past due, or still to come.
  String get ringOverWord;
  String get ringLeftWord;

  String get ringHintNew;
  String ringHintLeft(int n);
  String get ringHintDueToday;
  String ringHintOver(int n);

  /// The one status line under a card's day count.
  String get statusLearning;
  String statusDaysLeft(int n);
  String get statusDueToday;
  String statusDaysOver(int n);

  /// The unit beside the big number on a card.
  String get unitDaysSince;
  String get unitNoRecord;

  // ------------------------------------------------------------------- cards

  /// Ready-made cards on the "Yeni kart" page.
  List<NamedCard> get templates;

  /// The empty state's suggestions.
  List<NamedCard> get suggestions;

  /// "Ayarlar → Örnek kartları ekle": `(name, daysSinceLast, gaps)`.
  List<(String, int, List<int>)> get seedCards;

  /// A glyph's name, for screen readers — keyed like `cardGlyphs`.
  Map<String, String> get glyphLabels;

  /// A colour theme's name, keyed by [Palette.id].
  String themeName(String id);

  // ------------------------------------------------------------------ header

  String lateBadge(int n);
  String get lateBadgeHint;
  String get profile;
  String get listView;
  String get gridView;

  String get tabCards;
  String get tabTimeline;
  String get newCard;

  /// A card tile, read out: name, age, whether it is late, then the ring.
  String cardSemantics(String name, int days, bool late, String ringHint);
  String get hintOpenCard;
  String get hintOpenCardDrag;

  // -------------------------------------------------------------------- home

  String archiveLink(int n);
  String get noMatchingCards;
  String get searchCards;
  String get clearSearch;

  // ---------------------------------------------------------------- timeline

  String get timelineNew;
  String get timelineDueToday;
  String gapApart(int n);
  String get firstRecord;

  /// The age column on a timeline row.
  String timelineAge(int offset);

  String get rangeAll;
  String get rangeWeek;
  String get rangeMonth;
  String get timelineEmptyAll;
  String get timelineEmptyWeek;
  String get timelineEmptyMonth;
  String timelineRowSemantics(String date, String name, String age, String status);

  // --------------------------------------------------------------- gap chart

  String gapsSemantics(List<int> gaps, int? typical);
  String get gapOldest;
  String get gapNewest;
  String gapRhythm(int n);

  // ------------------------------------------------------------- empty state

  String get emptyTitle;
  String get emptyBody;
  String get emptyCta;
  String get suggestedCards;

  // ------------------------------------------------------------ record sheet

  String get whenDidYouDoIt;
  String get pickEarlier;
  String get pickFromCalendar;
  String get notYetDone;
  String get today;
  String get yesterday;
  String get twoDaysAgo;
  String daysAgoOn(int offset, String dow, String dom);

  // ------------------------------------------------------------ card details

  String get menuTurnOffReminder;
  String get menuRemindMe;
  String get menuReminderOffDetail;
  String get menuReminderOnDetail;
  String get toastReminderOn;
  String get menuEdit;
  String get menuEditDetail;
  String get menuAddDay;
  String get menuAddDayDetail;
  String get menuAddToHome;
  String get menuAddToHomeDetail;
  String get menuShare;
  String get menuShareDetail;
  String get menuUnarchive;
  String get menuArchive;
  String get menuUnarchiveDetail;
  String get menuArchiveDetail;
  String get menuDeleteCard;
  String get menuDeleteCardDetail;
  String confirmDeleteCardTitle(String name);
  String get confirmDeleteCardMessage;
  String get cardOptions;
  String get archivedBanner;

  String get recordOverline;
  String get addNote;
  String get editNote;
  String get noteDetail;
  String get notePlaceholder;
  String get changeDate;
  String get changeDateDetail;
  String get newDate;
  String get move;
  String get deleteRecord;
  String get deleteRecordDetail;

  String daysSinceSemantics(int n);
  String get noRecordYetLower;
  String get didItTodayLower;
  String get factLastRecord;
  String get factGoal;
  String get factAverage;
  String nDays(int n);
  String actualAverage(int n);
  String get markedToday;
  String get didItToday;
  String get pickAnotherDay;
  String get sectionGaps;
  String get sectionHistory;
  String nRecords(int n);
  String get historyEmpty;
  String get showLess;
  String showAll(int n);
  String historySemantics(String date, int? gap, String? note);

  // --------------------------------------------------------------- card form

  String get notifyPermissionOff;
  String notifyHintRhythm(String time);
  String get notifyHintNoRhythm;
  String get cardReminderTime;
  String get pickIcon;
  String get editCardTitle;
  String get whatDidYouDo;
  String get namePlaceholder;
  String get howOften;
  String get customFrequency;
  String get frequencyHintNone;
  String frequencyHint(String label);
  String get remindMe;
  String reminderTimeSemantics(String time);
  String get timeGlobal;
  String get timeThisCard;
  String get backToGlobalTime;
  String get advancedOptions;
  String get iconLabel;
  String get createCard;
  String get everyHowManyDays;
  String get decrease;
  String get increase;
  String get dayIntervalUnit;
  String get autoShort;
  String get autoIcon;
  String get readyMadeCards;

  // ------------------------------------------------------------- late screen

  String get lateTitle;
  String get swipeRightIfDone;
  String lateBanner(int n);
  String get lateBannerSub;
  String get allClear;
  String get allClearSub;

  // ----------------------------------------------------------------- archive

  String get archiveTitle;
  String get archiveEmpty;
  String get archiveNote;

  // ------------------------------------------------------------------ legend

  String get legendTitle;
  String get legendLead;

  /// Fresh, calm, soon, late — in that order.
  List<LegendRow> get legendRows;
  String get ringSectionTitle;
  String get ringSectionBody;

  // ------------------------------------------------------------------- theme

  String get themeTitle;
  String get themeLead;
  String get themeNote;
  String themeSemantics(String name);

  // ----------------------------------------------------------------- profile

  String get profileTitle;
  String get settings;
  String get addYourName;
  String editProfileSemantics(String name);
  String get tapToPersonalise;
  String get tapToEdit;
  String get statTotalCards;
  String get statTotalRecords;
  String get statNewThisMonth;
  String get monthSummary;
  String recordsMade(int n);
  String get vsLastMonth;
  String get insightRegular;
  String insightRegularDetail(int n);
  String get insightRegularEmpty;
  String get insightNeglected;
  String get insightNeglectedEmpty;
  String get fieldName;
  String get fieldNameHint;
  String get fieldHandle;
  String get fieldHandleHint;

  // ---------------------------------------------------------------- settings

  String get settingsTitle;
  String get groupAppearance;
  String get groupProfile;
  String get groupCards;
  String get groupNotifications;
  String get groupHomeWidget;
  String get groupBackup;
  String get groupDanger;
  String get groupAbout;

  String get language;
  String get languageSystem;

  String get theme;
  String get editProfile;
  String get statusColours;
  String get statusColoursDetail;
  String get resetOrder;
  String get resetOrderDetail;
  String get resetOrderNoop;
  String get archive;
  String get archiveEmptyDetail;
  String archiveCount(int n);
  String get importShared;
  String get importSharedDetail;
  String get loadSamples;
  String get loadSamplesDetail;
  String get samplesAlreadyThere;

  String get reminderTime;
  String get reminderTimeNoneDetail;
  String reminderTimeCount(int n);
  String get sendTestNotification;
  String get sendTestNotificationDetail;

  String get addCardWidget;
  String get addCardWidgetDetail;
  String get addListWidget;
  String get addListWidgetDetail;
  String get addHomeWidget;
  String get addHomeWidgetDetail;
  String get doneButtonSetting;
  String get doneButtonSettingDetail;

  String get systemBackup;
  String get systemBackupDetail;
  List<String> get systemBackupExplainer;
  String get copyBackup;
  String get copyBackupDetail;
  String get restoreBackup;
  String get restoreBackupDetail;
  String get exportCsv;
  String get exportCsvDetail;
  String get csvSubject;
  String get csvHeader;

  String get backupCopied;
  String get noBackupOnClipboard;
  String get restoreTitle;
  String get restoreMessage;
  String get notAValidBackup;
  String get noSharedCardOnClipboard;

  String get deleteAllCards;
  String get notUndoable;
  String get deleteAllTitle;
  String get deleteAllMessage;

  String get privacyPolicyRow;
  String get privacyPolicyRowDetail;
  String get termsRow;
  String get openSourceLicenses;
  String versionLine(String version);
  String get dataStaysHere;
  String lastUpdated(String date);
  String get legalContactTitle;

  // ------------------------------------------------------------ home widgets

  String get widgetPinned;
  String get widgetCantPinTitle;
  String get widgetCantPinBody;
  String get widgetOpenPermission;
  String get widgetShowManual;
  List<String> widgetHelpSteps({required bool ios, String? pick});
  String get widgetHelpTitle;
  String get widgetHelpBody;

  /// Drawn by the home screen widgets themselves (Kotlin/Swift), so they
  /// travel in the snapshot as `{n}` templates.
  Map<String, String> get widgetStrings;

  // ------------------------------------------------------------- reminders &

  String get notificationChannelName;
  String get notificationChannelDescription;

  /// Per topic: the lines for the due day, and the lines for a late card.
  Map<ReminderTopic, (List<String>, List<String>)> get reminderCopy;

  /// The card a test notification pretends to be about.
  String get sampleCardName;

  // -------------------------------------------------------------- store/undo

  String recordedSnack(String name, String relative);
  String cardAdded(String name);
  String cardDeleted(String name);
  String recordDeleted(String date);
  String recordMoved(String date);
  String get noteSaved;
  String get noteDeleted;
  String cardArchived(String name);
  String cardUnarchived(String name);
  String cardAlreadyThere(String name);
  String get cardUpdated;
  String get orderReset;
  String get allCardsDeleted;
  String samplesAdded(int n);
  String cardsRestored(int n);
  String widgetMarkedOne(String name);
  String widgetMarkedMany(int n);

  // ------------------------------------------------------------------- share

  String shareMessage(String name, String link);

  // ------------------------------------------------------------------ casing

  /// Uppercase the whole string, following this language's casing rules.
  String upper(String text);

  /// Capitalise the first letter, following this language's casing rules.
  String capitalize(String text);
}
