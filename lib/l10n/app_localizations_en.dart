// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MasterJi';

  @override
  String get appTagline => 'Check OMR sheets in seconds';

  @override
  String get namaskar => 'Namaskar';

  @override
  String namaskarName(String name) {
    return 'Namaskar, $name';
  }

  @override
  String today(String date) {
    return 'Today, $date';
  }

  @override
  String get home => 'Home';

  @override
  String get exams => 'Exams';

  @override
  String get lessonPlans => 'Lesson Plans';

  @override
  String get profile => 'Profile';

  @override
  String get quickScan => 'Quick Scan';

  @override
  String get quickScanSubtitle =>
      'Scan answer key, then student sheets. No setup.';

  @override
  String get examsScanSubtitle => 'Scan OMR by exam';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get youGet20FreeScans => 'You get 20 free scans';

  @override
  String freeScansLeft(int count) {
    return '$count free scans left';
  }

  @override
  String get premiumBadge => 'Premium';

  @override
  String get premium => 'Premium';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get premiumTitle => 'Go Premium';

  @override
  String get unlimitedScans => 'Unlimited scans';

  @override
  String get createExamsWithSets => 'Create exams with sets';

  @override
  String get classAndSectionResults => 'Class & section wise results';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get bestValue => 'Best value';

  @override
  String get pay => 'Pay';

  @override
  String get paymentsComingSoon => 'Payments coming soon';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get continueWithGoogleToUpgrade => 'Continue with Google to upgrade';

  @override
  String get scanAnswerKey => 'Scan answer key';

  @override
  String get enterManually => 'Enter manually instead';

  @override
  String get useThisKey => 'Use this key';

  @override
  String get nextSheet => 'Next sheet';

  @override
  String get rescanThisSheet => 'Rescan this sheet';

  @override
  String get finish => 'Finish';

  @override
  String get correct => 'Correct';

  @override
  String get wrong => 'Wrong';

  @override
  String get skipped => 'Skipped';

  @override
  String get marks => 'Marks';

  @override
  String get seeAnswers => 'See answers';

  @override
  String get hideAnswers => 'Hide answers';

  @override
  String get checking => 'Checking…';

  @override
  String sheetNumber(int number) {
    return 'Sheet #$number';
  }

  @override
  String get continueScanning => 'Continue scanning';

  @override
  String get clearSession => 'Clear session';

  @override
  String get sessionSummary => 'Session Summary';

  @override
  String sheets(int count) {
    return '$count sheets';
  }

  @override
  String get average => 'Average';

  @override
  String get highest => 'Highest';

  @override
  String get lowest => 'Lowest';

  @override
  String get mostMissed => 'Most missed questions';

  @override
  String get createExam => 'Create Exam';

  @override
  String get newExam => '+ New Exam';

  @override
  String get examName => 'Exam name';

  @override
  String get examNameHint => 'e.g. Half Yearly 2026';

  @override
  String get subjects => 'Subjects';

  @override
  String get subject => 'Subject';

  @override
  String get classesAndSections => 'Classes & Sections';

  @override
  String get class_ => 'Class';

  @override
  String get sections => 'Sections';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get questionCount => 'Number of questions';

  @override
  String get custom => 'Custom';

  @override
  String get marksPerCorrect => 'Marks per correct answer';

  @override
  String get negativeMarking => 'Negative marking';

  @override
  String get penaltyPerWrong => 'Penalty per wrong answer';

  @override
  String get paperHasSets => 'This paper has different sets';

  @override
  String get set_ => 'Set';

  @override
  String get addAnswerKey => 'Add answer key';

  @override
  String get answerKeyAdded => 'Answer key added ✓';

  @override
  String get answerKeyMissing => 'Key missing';

  @override
  String get scanOMR => 'Scan OMR';

  @override
  String get paperSettings => 'Paper settings';

  @override
  String get logIn => 'Log in';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirm =>
      'Are you sure you want to log out? Your local data stays on this device.';

  @override
  String get guestMode => 'You\'re using MasterJi as a guest';

  @override
  String get planFree => 'Free plan';

  @override
  String get planPremium => '👑 Premium';

  @override
  String get unlimitedScansShort => 'Unlimited scans · Exams unlocked';

  @override
  String freeScansProgress(int used) {
    return '$used of 20 free scans used';
  }

  @override
  String get school => 'School';

  @override
  String get schoolHint => 'Your school name (optional)';

  @override
  String get editSchool => 'Edit school';

  @override
  String get language => 'Language';

  @override
  String get helpAndShare => 'Help & Share';

  @override
  String get whatsappSupport => 'WhatsApp support';

  @override
  String get shareApp => 'Share app';

  @override
  String get rateApp => 'Rate app';

  @override
  String get aboutAndPrivacy => 'About & privacy';

  @override
  String get version => 'Version';

  @override
  String get notifyMe => 'Notify me';

  @override
  String get wellLetYouKnow => 'We\'ll let you know!';

  @override
  String get lessonPlansDescription =>
      'Personalised lesson plans for your class, coming soon.';

  @override
  String get whichSubjectMost => 'Which do you need most?';

  @override
  String get noExamsYet => 'No exams yet';

  @override
  String get createFirstExam => 'Create your first exam';

  @override
  String get tryQuickScanInstead => 'Try Quick Scan instead';

  @override
  String get checkOMRInSeconds => 'Check OMR sheets in seconds';

  @override
  String get loginBanner => 'Log in with Google to keep your account safe';

  @override
  String get quickScanInProgress => 'Quick Scan in progress';

  @override
  String get continueCurrentKey => 'Continue with the current answer key?';

  @override
  String get startNew => 'Start new';

  @override
  String get continue_ => 'Continue';

  @override
  String get saveAsExam => 'Save as an exam';

  @override
  String filledCount(int count, int total) {
    return '$count / $total filled';
  }

  @override
  String get jumpToQuestion => 'Jump to question';

  @override
  String nowScanningSet(String set) {
    return 'Now scanning $set';
  }

  @override
  String get noAnswerKey => 'No answer key added yet';

  @override
  String get addAnswerKeyFirst => 'Add the answer key before scanning';

  @override
  String get debugSection => 'Debug panel (dev only)';

  @override
  String get resetFreeScans => 'Reset free scans to 20';

  @override
  String get isLoggedInMock => 'Logged in (mock)';

  @override
  String get isPremiumMock => 'Premium (mock)';

  @override
  String subjectCount(int count) {
    return '$count subjects';
  }

  @override
  String answerKeysProgress(int done, int total) {
    return '$done of $total answer keys added';
  }

  @override
  String get recentlyUsed => 'Continue';

  @override
  String get startScanning => 'Start scanning';

  @override
  String get selectExam => 'Select exam';

  @override
  String get selectSubject => 'Select subject';

  @override
  String get selectClass => 'Select class & section';

  @override
  String get selectSet => 'Select set';

  @override
  String get gallery => 'Gallery';

  @override
  String confirmDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get confirmDeleteBody => 'This action cannot be undone.';

  @override
  String get successExamCreated => 'Exam created!';

  @override
  String get noSheetsYet => 'No sheets scanned yet';

  @override
  String get free20Left => '20 free scans left';

  @override
  String get used20Scans =>
      'You\'ve used your 20 free scans. Go Premium to keep scanning and create exams.';

  @override
  String get odia => 'ଓଡ଼ିଆ';

  @override
  String get english => 'English';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get tapToSwitch => 'Tap to switch language any time in Profile';

  @override
  String classLabel(int num) {
    return 'Class $num';
  }

  @override
  String sectionLabel(String letter) {
    return 'Section $letter';
  }

  @override
  String setLabel(String letter) {
    return 'Set $letter';
  }

  @override
  String paperLabel(String subject, int classNum) {
    return '$subject · Class $classNum';
  }

  @override
  String get oriya => 'Odia';

  @override
  String get math => 'Math';

  @override
  String get science => 'Science';

  @override
  String get socialScience => 'Social Science';

  @override
  String get hindi => 'Hindi';

  @override
  String get sanskrit => 'Sanskrit';

  @override
  String get english2 => 'English';

  @override
  String get addOther => 'Add other';

  @override
  String get enterQuestion => 'Enter question number';

  @override
  String get privacyPlaceholder =>
      'MasterJi respects your privacy. All your data is stored only on your device. No personal data is collected or shared with third parties.\n\nFor support, contact us on WhatsApp.';

  @override
  String classSectionSet(
      String subject, int classNum, String section, String set) {
    return '$subject · Class $classNum-$section · $set';
  }

  @override
  String sheetsChecked(int count) {
    return '$count sheets checked';
  }

  @override
  String scoreFormula(int correct, String marksPerCorrect, int wrong,
      String penalty, String total) {
    return '$correct × $marksPerCorrect − $wrong × $penalty = $total';
  }

  @override
  String get examBenefitSets => 'Sets A/B/C/D supported';

  @override
  String get examBenefitClass => 'Class & section wise';

  @override
  String get lessonPlansComingSoon => 'Coming soon';

  @override
  String get examBenefitKeys => 'Save answer keys for every paper';
}
