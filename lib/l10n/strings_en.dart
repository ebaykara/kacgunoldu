import '../domain/reminder_copy.dart' show ReminderTopic;
import 'strings.dart';

/// English. The product name stays "Kaç Gün Oldu?" — it is the brand on both
/// stores — but every line the app speaks is translated, in the same plain,
/// slightly wry voice as the Turkish.
class EnStrings extends Strings {
  const EnStrings();

  @override
  AppLang get lang => AppLang.en;

  @override
  String get langName => 'English';

  @override
  String get appHeadline => 'How many days?';

  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'OK';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get deleteAll => 'Delete all';
  @override
  String get back => 'Back';
  @override
  String get close => 'Close';
  @override
  String get undo => 'Undo';
  @override
  String get select => 'Select';
  @override
  String get restore => 'Restore';

  // -------------------------------------------------------------------- date

  @override
  List<String> get dow => const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  List<String> get months => const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  List<String> get monthsShort => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  String dayMonth(int day, int month, {int? year}) =>
      '${months[month - 1]} $day${year == null ? '' : ', $year'}';

  @override
  String fullDate(int day, int month, int year) => '${months[month - 1]} $day, $year';

  @override
  String get relToday => 'today';
  @override
  String get relYesterday => 'yesterday';
  @override
  String relDaysAgo(int n) => '$n days ago';
  @override
  String relWeeksAgo(int n) => n == 1 ? 'a week ago' : '$n weeks ago';
  @override
  String relMonthsAgo(int n) => n == 1 ? 'a month ago' : '$n months ago';

  // --------------------------------------------------------------- frequency

  @override
  List<(int, String)> get frequencyPresets => const [
    (1, 'Every day'),
    (2, 'Every 2 days'),
    (3, 'Every 3 days'),
    (7, 'Weekly'),
    (14, 'Every 2 weeks'),
    (30, 'Monthly'),
    (60, 'Every 2 months'),
    (90, 'Every 3 months'),
    (180, 'Every 6 months'),
    (365, 'Yearly'),
  ];

  @override
  String everyNDays(int days) => 'Every $days days';

  @override
  String goalSuffix(String frequencyLabel) =>
      ' Your goal: ${frequencyLabel.toLowerCase()}.';

  // ------------------------------------------------------------------ filter

  @override
  String get filterAll => 'All';
  @override
  String get filterLate => 'Overdue';
  @override
  String get filterSoon => 'Due soon';

  // ------------------------------------------------------- stats & card face

  @override
  String get notMarkedYet => 'Not marked yet';
  @override
  String get doneTodayMeta => 'Done today';

  @override
  String metaEvery(String date, int typical) => '$date ~every $typical days';

  @override
  String get ringNew => 'new';
  @override
  String ringDays(int n) => '$n days';
  @override
  String get ringToday => 'today';
  @override
  String ringOver(int n) => '+$n days';
  @override
  String get ringUnitSuffix => ' days';
  @override
  String get ringUnit => 'days';
  @override
  String get ringOverWord => 'over';
  @override
  String get ringLeftWord => 'left';

  @override
  String get ringHintNew => 'rhythm not learned yet';
  @override
  String ringHintLeft(int n) => '$n days left of the usual interval';
  @override
  String get ringHintDueToday => 'the usual interval is up today';
  @override
  String ringHintOver(int n) => '$n days past the usual interval';

  @override
  String get statusLearning => 'Learning the rhythm';
  @override
  String statusDaysLeft(int n) => '$n days left';
  @override
  String get statusDueToday => 'Due today';
  @override
  String statusDaysOver(int n) => '$n days over';

  @override
  String get unitDaysSince => 'days ago';
  @override
  String get unitNoRecord => 'no records';

  // ------------------------------------------------------------------- cards

  @override
  List<NamedCard> get templates => const [
    ('Changed my toothbrush', 'tooth', 90),
    ('Cleaned the AC filter', 'home', 90),
    ('Changed the car oil', 'car', 365),
    ('Pumped up the tyres', 'car', 30),
    ('Changed the duvet cover', 'bed', 14),
    ('Washed the towels', 'laundry', 7),
    ('Cleaned the fridge', 'fridge', 30),
    ('Cleaned the bathroom', 'bath', 7),
    ('Watered the plants', 'plant', 3),
    ('Got a haircut', 'scissors', 30),
    ('Went to the dentist', 'tooth', 180),
    ('Had a blood test', 'doctor', 365),
    ('Took the pet to the vet', 'pet', 365),
    ('Called my mum', 'phone', 7),
    ('Paid the rent', 'money', 30),
    ('Finished a book', 'book', 30),
  ];

  @override
  List<NamedCard> get suggestions => const [
    ('Got a haircut', 'scissors', 30),
    ('Went to the dentist', 'tooth', 180),
    ('Went to the gym', 'gym', 3),
    ('Changed the sheets', 'bed', 14),
    ('Watered the plants', 'plant', 3),
    ('Called my mum', 'phone', 7),
  ];

  @override
  List<(String, int, List<int>)> get seedCards => const [
    ('Went to the dentist', 214, [186, 192]),
    ('Went to the gym', 11, [3, 4, 2, 3]),
    ('Got a haircut', 46, [34, 38]),
    ('Changed the sheets', 9, [11, 12, 10]),
    ('Called my mum', 3, [4, 2, 5]),
    ('Watered the plants', 5, [4, 3, 4]),
    ('Changed the car oil', 121, [160, 175]),
    ('Cleaned the fridge', 28, [30, 26]),
    ('Went swimming', 17, [9, 8, 11]),
  ];

  @override
  Map<String, String> get glyphLabels => const {
    'gym': 'gym',
    'swim': 'swimming',
    'run': 'running',
    'bike': 'bike',
    'bed': 'bed',
    'scissors': 'scissors',
    'tooth': 'tooth',
    'doctor': 'doctor',
    'pill': 'medicine',
    'plant': 'plant',
    'fridge': 'fridge',
    'clean': 'cleaning',
    'laundry': 'laundry',
    'bath': 'bathroom',
    'phone': 'phone',
    'car': 'car',
    'book': 'book',
    'pet': 'pet',
    'cart': 'shopping',
    'coffee': 'coffee',
    'music': 'music',
    'money': 'money',
    'mail': 'mail',
    'heart': 'heart',
    'home': 'home',
    'spark': 'spark',
  };

  @override
  String themeName(String id) => switch (id) {
    'okyanus' => 'Ocean',
    'orman' => 'Forest',
    'lavanta' => 'Lavender',
    'gul' => 'Rose',
    'gece' => 'Night',
    _ => 'Terracotta',
  };

  // ------------------------------------------------------------------ header

  @override
  String lateBadge(int n) => n == 1 ? '1 card overdue' : '$n cards overdue';
  @override
  String get lateBadgeHint => 'tap to see what is overdue';
  @override
  String get profile => 'Profile';
  @override
  String get listView => 'List view';
  @override
  String get gridView => 'Grid view';

  @override
  String get tabCards => 'Cards';
  @override
  String get tabTimeline => 'Timeline';
  @override
  String get newCard => 'New card';

  @override
  String cardSemantics(String name, int days, bool late, String ringHint) =>
      '$name, $days days ago${late ? ', overdue' : ''}. $ringHint';
  @override
  String get hintOpenCard => 'tap for details';
  @override
  String get hintOpenCardDrag => 'tap for details, press and hold to drag it elsewhere';

  // -------------------------------------------------------------------- home

  @override
  String archiveLink(int n) => 'Archive ($n)';
  @override
  String get noMatchingCards => 'No matching cards.';
  @override
  String get searchCards => 'Search cards';
  @override
  String get clearSearch => 'Clear search';

  // ---------------------------------------------------------------- timeline

  @override
  String get timelineNew => 'New';
  @override
  String get timelineDueToday => 'due today';
  @override
  String gapApart(int n) => '$n days apart';
  @override
  String get firstRecord => 'first record';

  @override
  String timelineAge(int offset) => switch (offset) {
    0 => 'today',
    1 => 'yesterday',
    _ => '$offset days',
  };

  @override
  String get rangeAll => 'All';
  @override
  String get rangeWeek => 'Week';
  @override
  String get rangeMonth => 'Month';
  @override
  String get timelineEmptyAll => 'No records yet.';
  @override
  String get timelineEmptyWeek => 'No records in the last week.';
  @override
  String get timelineEmptyMonth => 'No records in the last month.';
  @override
  String timelineRowSemantics(String date, String name, String age, String status) =>
      '$date, $name, $age, $status';

  // --------------------------------------------------------------- gap chart

  @override
  String gapsSemantics(List<int> gaps, int? typical) =>
      'Gaps between records: ${gaps.join(', ')} days'
      '${typical != null ? '. Rhythm $typical days' : ''}';
  @override
  String get gapOldest => 'oldest';
  @override
  String get gapNewest => 'newest';
  @override
  String gapRhythm(int n) => 'rhythm $n days';

  // ------------------------------------------------------------- empty state

  @override
  String get emptyTitle => 'Start keeping track of\nthe little things.';
  @override
  String get emptyBody => 'Add something you wonder when\nyou last did.';
  @override
  String get emptyCta => 'Create your first card';
  @override
  String get suggestedCards => 'Suggested cards';

  // ------------------------------------------------------------ record sheet

  @override
  String get whenDidYouDoIt => 'When did you do it?';
  @override
  String get pickEarlier => 'Pick an earlier day';
  @override
  String get pickFromCalendar => 'Pick from the calendar';
  @override
  String get notYetDone => 'Haven’t done it yet';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get twoDaysAgo => '2 days ago';
  @override
  String daysAgoOn(int offset, String dow, String dom) => '$offset days ago, $dow $dom';

  // ------------------------------------------------------------ card details

  @override
  String get menuTurnOffReminder => 'Turn off the reminder';
  @override
  String get menuRemindMe => 'Remind me';
  @override
  String get menuReminderOffDetail => 'No notifications for this card';
  @override
  String get menuReminderOnDetail => 'Notify me when it comes due';
  @override
  String get toastReminderOn => 'Reminder on';
  @override
  String get menuEdit => 'Edit';
  @override
  String get menuEditDetail => 'Name, icon and frequency';
  @override
  String get menuAddDay => 'Add another day';
  @override
  String get menuAddDayDetail => 'Add a record in the past';
  @override
  String get menuAddToHome => 'Add to home screen';
  @override
  String get menuAddToHomeDetail => 'Show this card as a widget';
  @override
  String get menuShare => 'Share';
  @override
  String get menuShareDetail => 'Send someone a copy of this card';
  @override
  String get menuUnarchive => 'Unarchive';
  @override
  String get menuArchive => 'Archive';
  @override
  String get menuUnarchiveDetail => 'It comes back among your cards';
  @override
  String get menuArchiveDetail =>
      'Records stay; it leaves the list and stops reminding you';
  @override
  String get menuDeleteCard => 'Delete card';
  @override
  String get menuDeleteCardDetail => 'Together with all of its records';
  @override
  String confirmDeleteCardTitle(String name) => 'Delete “$name”?';
  @override
  String get confirmDeleteCardMessage =>
      'Every record on this card is permanently deleted. This cannot be undone.';
  @override
  String get cardOptions => 'Card options';
  @override
  String get archivedBanner => 'This card is archived';

  @override
  String get recordOverline => 'Record';
  @override
  String get addNote => 'Add a note';
  @override
  String get editNote => 'Edit the note';
  @override
  String get noteDetail => 'E.g. mileage, what was done';
  @override
  String get notePlaceholder => 'E.g. 45,200 km, one filling';
  @override
  String get changeDate => 'Change the date';
  @override
  String get changeDateDetail => 'Move this record to another day';
  @override
  String get newDate => 'New date';
  @override
  String get move => 'Move';
  @override
  String get deleteRecord => 'Delete this record';
  @override
  String get deleteRecordDetail => 'You can undo it';

  @override
  String daysSinceSemantics(int n) => '$n days ago';
  @override
  String get noRecordYetLower => 'no records yet';
  @override
  String get didItTodayLower => 'done today';
  @override
  String get factLastRecord => 'Last record';
  @override
  String get factGoal => 'Goal';
  @override
  String get factAverage => 'Average';
  @override
  String nDays(int n) => '$n days';
  @override
  String actualAverage(int n) => 'In practice you do this about every $n days.';
  @override
  String get markedToday => 'Marked today';
  @override
  String get didItToday => 'Did it today';
  @override
  String get pickAnotherDay => 'Pick another day';
  @override
  String get sectionGaps => 'Intervals';
  @override
  String get sectionHistory => 'History';
  @override
  String nRecords(int n) => n == 1 ? '1 record' : '$n records';
  @override
  String get historyEmpty =>
      'No records yet. Mark it with the button above once you do it.';
  @override
  String get showLess => 'Show less';
  @override
  String showAll(int n) => 'Show all ($n)';
  @override
  String historySemantics(String date, int? gap, String? note) =>
      '$date${gap != null ? ', $gap days apart' : ''}'
      '${note != null ? ', note: $note' : ''}';

  // --------------------------------------------------------------- card form

  @override
  String get notifyPermissionOff =>
      'Notifications are off. You can turn them on in your phone’s settings.';
  @override
  String notifyHintRhythm(String time) => 'I’ll let you know around $time when it is due.';
  @override
  String get notifyHintNoRhythm =>
      'I’ll let you know once I learn its rhythm (after 3 records), or pick a frequency.';
  @override
  String get cardReminderTime => 'This card’s reminder time';
  @override
  String get pickIcon => 'Pick an icon';
  @override
  String get editCardTitle => 'Edit card';
  @override
  String get whatDidYouDo => 'What did you do?';
  @override
  String get namePlaceholder => 'E.g. Got a haircut';
  @override
  String get howOften => 'How often do you repeat it?';
  @override
  String get customFrequency => 'Custom';
  @override
  String get frequencyHintNone => 'Skip it and I’ll learn the rhythm from your records.';
  @override
  String frequencyHint(String label) =>
      '“$label” means the card turns “overdue” once that interval is clearly passed.';
  @override
  String get remindMe => 'Remind me';
  @override
  String reminderTimeSemantics(String time) => 'Reminder time $time';
  @override
  String get timeGlobal => 'Time (global setting)';
  @override
  String get timeThisCard => 'This card’s time';
  @override
  String get backToGlobalTime => 'Back to the global time';
  @override
  String get advancedOptions => 'Advanced options';
  @override
  String get iconLabel => 'Icon';
  @override
  String get createCard => 'Create card';
  @override
  String get everyHowManyDays => 'Every how many days?';
  @override
  String get decrease => 'Decrease';
  @override
  String get increase => 'Increase';
  @override
  String get dayIntervalUnit => 'days';
  @override
  String get autoShort => 'auto';
  @override
  String get autoIcon => 'Automatic icon';
  @override
  String get readyMadeCards => 'Ready-made cards';

  // ------------------------------------------------------------- late screen

  @override
  String get lateTitle => 'Overdue';
  @override
  String get swipeRightIfDone => 'Swipe right if you did it';
  @override
  String lateBanner(int n) =>
      n == 1 ? '1 card is past due' : '$n cards are past due';
  @override
  String get lateBannerSub => 'Check them now and plan the next time.';
  @override
  String get allClear => 'All clear.';
  @override
  String get allClearSub => 'Nothing is overdue — a rare day.';

  // ----------------------------------------------------------------- archive

  @override
  String get archiveTitle => 'Archive';
  @override
  String get archiveEmpty =>
      'Nothing in the archive. You can archive a card from its ⋯ menu.';
  @override
  String get archiveNote =>
      'Archived cards stay out of your list, never count as overdue and never '
      'remind you. Their records are kept as they are.';

  // ------------------------------------------------------------------ legend

  @override
  String get legendTitle => 'Status colours';
  @override
  String get legendLead => 'A card’s colour tells you where it stands.';

  @override
  List<LegendRow> get legendRows => const [
    (
      'Fresh',
      'You did it recently; not even half of the usual interval has passed.',
      'Changed the sheets',
    ),
    ('Normal', 'All good, it is not due yet.', 'Watered the plants'),
    ('Coming up', 'The usual interval is nearly up, or just up.', 'Got a haircut'),
    ('Overdue', 'It is clearly past the usual interval.', 'Went to the gym'),
  ];

  @override
  String get ringSectionTitle => 'What does the ring show?';
  @override
  String get ringSectionBody =>
      'The ring shows how long there is until the next time. '
      '“4 days” means four days left, “today” means it is due today, “+8 days” '
      'means it is eight days past the usual interval. “new” means the rhythm '
      'is not learned yet — it is learned after three records, or as soon as '
      'you pick a frequency.';

  // ------------------------------------------------------------------- theme

  @override
  String get themeTitle => 'Theme';
  @override
  String get themeLead => 'Choose your colours.';
  @override
  String get themeNote =>
      'Card statuses mean the same in every theme: an overdue card is always the darkest.';
  @override
  String themeSemantics(String name) => '$name theme';

  // ----------------------------------------------------------------- profile

  @override
  String get profileTitle => 'Profile';
  @override
  String get settings => 'Settings';
  @override
  String get addYourName => 'Add your name';
  @override
  String editProfileSemantics(String name) => '$name, edit profile';
  @override
  String get tapToPersonalise => 'Tap to personalise your profile';
  @override
  String get tapToEdit => 'Tap to edit';
  @override
  String get statTotalCards => 'Total cards';
  @override
  String get statTotalRecords => 'Total records';
  @override
  String get statNewThisMonth => 'New this month';
  @override
  String get monthSummary => 'This month';
  @override
  String recordsMade(int n) => n == 1 ? 'You made 1 record' : 'You made $n records';
  @override
  String get vsLastMonth => 'Against last month ';
  @override
  String get insightRegular => 'Your most regular';
  @override
  String insightRegularDetail(int n) => 'About every $n days';
  @override
  String get insightRegularEmpty => 'Shows up here after three records.';
  @override
  String get insightNeglected => 'Left alone the longest';
  @override
  String get insightNeglectedEmpty => 'No records yet.';
  @override
  String get fieldName => 'Your name';
  @override
  String get fieldNameHint => 'Type your name';
  @override
  String get fieldHandle => 'Username';
  @override
  String get fieldHandleHint => 'optional';

  // ---------------------------------------------------------------- settings

  @override
  String get settingsTitle => 'Settings';
  @override
  String get groupAppearance => 'Appearance';
  @override
  String get groupProfile => 'Profile';
  @override
  String get groupCards => 'Cards';
  @override
  String get groupNotifications => 'Notifications';
  @override
  String get groupHomeWidget => 'Home screen widget';
  @override
  String get groupBackup => 'Backup';
  @override
  String get groupDanger => 'Danger zone';
  @override
  String get groupAbout => 'About';

  @override
  String get language => 'Language';
  @override
  String get languageSystem => 'Phone’s language';

  @override
  String get theme => 'Theme';
  @override
  String get editProfile => 'Edit profile';
  @override
  String get statusColours => 'Status colours';
  @override
  String get statusColoursDetail => 'What does a card’s colour mean?';
  @override
  String get resetOrder => 'Reset the order';
  @override
  String get resetOrderDetail =>
      'The order you dragged is forgotten and cards line up by urgency';
  @override
  String get resetOrderNoop => 'Cards are already ordered by urgency';
  @override
  String get archive => 'Archive';
  @override
  String get archiveEmptyDetail => 'Nothing in the archive';
  @override
  String archiveCount(int n) =>
      n == 1 ? '1 card archived' : '$n cards archived';
  @override
  String get importShared => 'Add a shared card';
  @override
  String get importSharedDetail => 'Copy the message you were sent, then tap';
  @override
  String get loadSamples => 'Add sample cards';
  @override
  String get loadSamplesDetail => 'Ready-made cards for trying the app out';
  @override
  String get samplesAlreadyThere => 'Every sample card is already here';

  @override
  String get reminderTime => 'Reminder time';
  @override
  String get reminderTimeNoneDetail => 'Turn on “Remind me” when you add a card';
  @override
  String reminderTimeCount(int n) =>
      n == 1 ? 'Reminders on for 1 card' : 'Reminders on for $n cards';
  @override
  String get sendTestNotification => 'Send a test notification';
  @override
  String get sendTestNotificationDetail => 'See what a notification looks like';

  @override
  String get addCardWidget => 'Add the Card widget';
  @override
  String get addCardWidgetDetail => 'How many days it has been for one card';
  @override
  String get addListWidget => 'Add the Cards widget';
  @override
  String get addListWidgetDetail => 'The cards due soonest, together';
  @override
  String get addHomeWidget => 'Add a home screen widget';
  @override
  String get addHomeWidgetDetail => 'See your cards without opening the app';
  @override
  String get doneButtonSetting => '“Did it today” button';
  @override
  String get doneButtonSettingDetail => 'Mark it from the widget with one tap';

  @override
  String get systemBackup => 'Your phone’s backup';
  @override
  String get systemBackupDetail =>
      'With Google or iCloud backup on, your cards are backed up too';

  @override
  List<String> get systemBackupExplainer => const [
    'If Google account backup on Android, or iCloud backup on iPhone, is on, '
        'your cards and records go into that backup automatically.',
    'Restore from that backup while setting up a new phone and your cards come '
        'back by themselves; the reminders are set up again too.',
    'You can turn the backup on and off in your phone’s settings. Google or '
        'Apple keeps it; we cannot see it.',
    'The backup runs once a day, while the phone is charging and on Wi-Fi, so '
        'today’s latest records may not be in it yet.',
    'Restoring only happens while the app is being installed; you cannot go '
        'back to a backup once it is installed. On builds installed outside '
        'the store, restoring may not work on every phone.',
    'With the backup off, nothing is backed up. Use “Copy backup to clipboard” '
        'in Settings to keep your data by hand instead.',
  ];

  @override
  String get copyBackup => 'Copy backup to clipboard';
  @override
  String get copyBackupDetail => 'Paste it into your notes, or message it to yourself';
  @override
  String get restoreBackup => 'Restore the backup on the clipboard';
  @override
  String get restoreBackupDetail => 'Bring the backup you copied onto this device';
  @override
  String get exportCsv => 'Export as CSV';
  @override
  String get exportCsvDetail => 'Every record, opens in a spreadsheet';
  @override
  String get csvSubject => 'Kaç Gün Oldu? records';
  @override
  String get csvHeader => 'Card,Date,Note';

  @override
  String get backupCopied => 'Backup copied to the clipboard';
  @override
  String get noBackupOnClipboard => 'No backup on the clipboard';
  @override
  String get restoreTitle => 'Restore the backup?';
  @override
  String get restoreMessage =>
      'All of your current cards are replaced with the backup on the clipboard. '
      'This cannot be undone.';
  @override
  String get notAValidBackup => 'The text on the clipboard is not a valid backup';
  @override
  String get noSharedCardOnClipboard => 'No shared card on the clipboard';

  @override
  String get deleteAllCards => 'Delete every card';
  @override
  String get notUndoable => 'Cannot be undone';
  @override
  String get deleteAllTitle => 'Delete every card?';
  @override
  String get deleteAllMessage =>
      'Every card and its records are permanently deleted. This cannot be undone.';

  @override
  String get privacyPolicyRow => 'Privacy policy';
  @override
  String get privacyPolicyRowDetail => 'No data is collected';
  @override
  String get termsRow => 'Terms of use';
  @override
  String get openSourceLicenses => 'Open source licences';
  @override
  String versionLine(String version) => 'Kaç gün oldu? · $version';
  @override
  String get dataStaysHere => 'All of your data stays on this device.';
  @override
  String lastUpdated(String date) => 'Last updated: $date';
  @override
  String get legalContactTitle => 'Kaç Gün Oldu? · EMA Labs';

  // ------------------------------------------------------------ home widgets

  @override
  String get widgetPinned => 'Widget added to the home screen';
  @override
  String get widgetCantPinTitle => 'Your phone will not allow it';
  @override
  String get widgetCantPinBody =>
      'Choosing “Deny” in the confirmation window makes the phone block this '
      'request without asking again. Turn on “Home screen shortcuts” on the '
      'permissions page and try again.';
  @override
  String get widgetOpenPermission => 'Open permissions';
  @override
  String get widgetShowManual => 'Show me how to add it by hand';

  @override
  List<String> widgetHelpSteps({required bool ios, String? pick}) => ios
      ? [
          'Press and hold an empty spot on the home screen, then tap Edit → Add Widget at the top left.',
          'Pick Kaç Gün Oldu? from the list: Card for a single card, Cards for several.',
          pick == null
              ? 'To choose which card Card shows, press and hold the widget → Edit Widget.'
              : 'Press and hold the widget → Edit Widget → Card: $pick.',
          'You can add it to the lock screen too: press and hold the lock screen → Customise.',
        ]
      : [
          'Press and hold an empty spot on the home screen, then tap Widgets.',
          'Find Kaç Gün Oldu?: Card for a single card, Cards for several.',
          pick == null
              ? 'Once you add Card, it asks which card to show.'
              : 'Once you add Card, pick $pick from the list that opens.',
        ];

  @override
  String get widgetHelpTitle => 'Add a home screen widget';
  @override
  String get widgetHelpBody =>
      'See how many days it has been without opening the app; tap “Did it '
      'today” right on the widget.';

  @override
  Map<String, String> get widgetStrings => const {
    'title': 'How many days?',
    'late': '{n} cards overdue',
    'notMarked': 'Not marked yet',
    'learning': 'Learning the rhythm',
    'daysLeft': '{n} days left',
    'dueToday': 'Due today',
    'daysOver': '{n} days over',
    'unitDays': 'days ago',
    'unitNone': 'no records',
    'doneToday': 'Done today',
    'markDone': 'Did it today',
    'firstCard': 'Create your first card',
    'openApp': 'Open the app to see your cards',
  };

  // --------------------------------------------------------------- reminders

  @override
  String get notificationChannelName => 'Reminders';
  @override
  String get notificationChannelDescription =>
      'Tells you when a card is due again.';
  @override
  String get sampleCardName => 'Got a haircut';

  @override
  Map<ReminderTopic, (List<String>, List<String>)> get reminderCopy => const {
    ReminderTopic.hair: ([
      '{n} days. The barber misses you, and so does the mirror.',
      '{n} days. Your hair wants a fresh start.',
    ], [
      '{n} days. Your hair is making its own decisions now.',
      '{k} days over. Book something before the comb gives up?',
    ]),
    ReminderTopic.nails: ([
      '{n} days. The clippers are waiting in the drawer.',
    ], [
      '{k} days over. Five minutes of work, right now.',
    ]),
    ReminderTopic.plant: ([
      '{n} days without water. They are quiet, but they are taking notes.',
      '{n} days. One glass of water, a world of thanks.',
    ], [
      '{n} days. If a leaf turns yellow, we both know why.',
      '{k} days over. The pots are staging a silent protest.',
    ]),
    ReminderTopic.bed: ([
      '{n} days. You deserve a fresh bed tonight.',
    ], [
      '{n} days. The pillow agrees.',
    ]),
    ReminderTopic.fridge: ([
      '{n} days. Before the back shelf turns into a science project…',
    ], [
      '{k} days over. Let’s avoid surprises when the door opens.',
    ]),
    ReminderTopic.clean: ([
      '{n} days. Put a song on, fifteen minutes, done.',
      '{n} days. The dust has started organising.',
    ], [
      '{k} days over. Starting is the hard part, the rest is easy.',
    ]),
    ReminderTopic.laundry: ([
      '{n} days. The basket is nearly full, and you know it.',
    ], [
      '{k} days over. Your favourite shirt is waiting its turn.',
    ]),
    ReminderTopic.gym: ([
      '{n} days without the gym. The dumbbells are getting curious.',
      '{n} days. The gym bag looks good by the door.',
    ], [
      '{n} days. Your muscles have started a quiet strike.',
      '{k} days over. A short session counts too.',
    ]),
    ReminderTopic.outdoor: ([
      '{n} days. Outside is waiting for you.',
      '{n} days. The shoes are ready — are you?',
    ], [
      '{k} days over. Even twenty minutes makes a difference.',
    ]),
    ReminderTopic.family: ([
      '{n} days. Even a quick "how are you" makes the day better.',
      '{n} days. Hearing their voice does you good.',
    ], [
      '{n} days. The opening line writes itself: "Where have you been?"',
      '{k} days over. A two-minute call is enough.',
    ]),
    ReminderTopic.car: ([
      '{n} days. The engine cannot thank you, but it would.',
    ], [
      '{k} days over. Better a service than a breakdown.',
    ]),
    ReminderTopic.pet: ([
      '{n} days. Your four-legged flatmate is on board with this.',
    ], [
      '{k} days over. You can tell from the look — it is time.',
    ]),
    ReminderTopic.book: ([
      '{n} days. The bookmark is still on the same page.',
    ], [
      '{k} days over. A few pages is still reading.',
    ]),
    ReminderTopic.music: ([
      '{n} days. The instrument in the corner feels forgotten.',
    ], [
      '{k} days over. Play for ten minutes, the rest follows.',
    ]),
    ReminderTopic.bill: ([
      'It is time to pay. Shall we sort it before the last day?',
    ], [
      '{k} days over. Worth a look before a late fee shows up.',
    ]),
    ReminderTopic.doctor: ([
      'It has been {n} days since the last check-up. A good time to book one.',
    ], [
      'The check-up is {k} days overdue. Remember to book it when you can.',
    ]),
    ReminderTopic.pill: ([
      'It is due. You took it {n} days ago.',
    ], [
      '{k} days over. If you have done it, tap to mark it.',
    ]),
    ReminderTopic.general: ([
      '{n} days — just about time.',
      '{n} days. Today could be a good day for it.',
      '{n} days. It has been at the back of your mind, hasn’t it?',
    ], [
      '{n} days, {k} of them over. If you have done it, tap to mark it.',
      '{k} days over. Better late than never.',
    ]),
  };

  // -------------------------------------------------------------- store/undo

  @override
  String recordedSnack(String name, String relative) => '$name · $relative';
  @override
  String cardAdded(String name) => '“$name” added';
  @override
  String cardDeleted(String name) => '“$name” deleted';
  @override
  String recordDeleted(String date) => 'The record for $date was deleted';
  @override
  String recordMoved(String date) => 'The record was moved to $date';
  @override
  String get noteSaved => 'Note saved';
  @override
  String get noteDeleted => 'Note deleted';
  @override
  String cardArchived(String name) => '“$name” archived';
  @override
  String cardUnarchived(String name) => '“$name” is back';
  @override
  String cardAlreadyThere(String name) => '“$name” is already among your cards';
  @override
  String get cardUpdated => 'Card updated';
  @override
  String get orderReset => 'Cards ordered by urgency';
  @override
  String get allCardsDeleted => 'Every card deleted';
  @override
  String samplesAdded(int n) =>
      n == 1 ? '1 sample card added' : '$n sample cards added';
  @override
  String cardsRestored(int n) => n == 1 ? '1 card restored' : '$n cards restored';
  @override
  String widgetMarkedOne(String name) => '$name · recorded from the widget';
  @override
  String widgetMarkedMany(int n) => '$n records added from the widget';

  // ------------------------------------------------------------------- share

  @override
  String shareMessage(String name, String link) =>
      'I shared my “$name” card with you.\n'
      'Tap the link with Kaç Gün Oldu? installed, or copy this message and '
      'choose Settings → Add a shared card.\n\n'
      '$link';

  // ------------------------------------------------------------------ casing

  @override
  String upper(String text) => text.toUpperCase();

  @override
  String capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
