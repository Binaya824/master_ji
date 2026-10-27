import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_or.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('or')
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'MasterJi'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Check OMR sheets in seconds'**
  String get appTagline;

  /// No description provided for @namaskar.
  ///
  /// In en, this message translates to:
  /// **'Namaskar'**
  String get namaskar;

  /// No description provided for @namaskarName.
  ///
  /// In en, this message translates to:
  /// **'Namaskar, {name}'**
  String namaskarName(String name);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String today(String date);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @lessonPlans.
  ///
  /// In en, this message translates to:
  /// **'Lesson Plans'**
  String get lessonPlans;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @quickScan.
  ///
  /// In en, this message translates to:
  /// **'Quick Scan'**
  String get quickScan;

  /// No description provided for @quickScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan answer key, then student sheets. No setup.'**
  String get quickScanSubtitle;

  /// No description provided for @examsScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan OMR by exam'**
  String get examsScanSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @youGet20FreeScans.
  ///
  /// In en, this message translates to:
  /// **'You get 20 free scans'**
  String get youGet20FreeScans;

  /// No description provided for @freeScansLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} free scans left'**
  String freeScansLeft(int count);

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumBadge;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get premiumTitle;

  /// No description provided for @unlimitedScans.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scans'**
  String get unlimitedScans;

  /// No description provided for @createExamsWithSets.
  ///
  /// In en, this message translates to:
  /// **'Create exams with sets'**
  String get createExamsWithSets;

  /// No description provided for @classAndSectionResults.
  ///
  /// In en, this message translates to:
  /// **'Class & section wise results'**
  String get classAndSectionResults;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @paymentsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payments coming soon'**
  String get paymentsComingSoon;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @continueWithGoogleToUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google to upgrade'**
  String get continueWithGoogleToUpgrade;

  /// No description provided for @scanAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'Scan answer key'**
  String get scanAnswerKey;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually instead'**
  String get enterManually;

  /// No description provided for @useThisKey.
  ///
  /// In en, this message translates to:
  /// **'Use this key'**
  String get useThisKey;

  /// No description provided for @nextSheet.
  ///
  /// In en, this message translates to:
  /// **'Next sheet'**
  String get nextSheet;

  /// No description provided for @rescanThisSheet.
  ///
  /// In en, this message translates to:
  /// **'Rescan this sheet'**
  String get rescanThisSheet;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrong;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @marks.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get marks;

  /// No description provided for @seeAnswers.
  ///
  /// In en, this message translates to:
  /// **'See answers'**
  String get seeAnswers;

  /// No description provided for @hideAnswers.
  ///
  /// In en, this message translates to:
  /// **'Hide answers'**
  String get hideAnswers;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @sheetNumber.
  ///
  /// In en, this message translates to:
  /// **'Sheet #{number}'**
  String sheetNumber(int number);

  /// No description provided for @continueScanning.
  ///
  /// In en, this message translates to:
  /// **'Continue scanning'**
  String get continueScanning;

  /// No description provided for @clearSession.
  ///
  /// In en, this message translates to:
  /// **'Clear session'**
  String get clearSession;

  /// No description provided for @sessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Session Summary'**
  String get sessionSummary;

  /// No description provided for @sheets.
  ///
  /// In en, this message translates to:
  /// **'{count} sheets'**
  String sheets(int count);

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @mostMissed.
  ///
  /// In en, this message translates to:
  /// **'Most missed questions'**
  String get mostMissed;

  /// No description provided for @createExam.
  ///
  /// In en, this message translates to:
  /// **'Create Exam'**
  String get createExam;

  /// No description provided for @newExam.
  ///
  /// In en, this message translates to:
  /// **'+ New Exam'**
  String get newExam;

  /// No description provided for @examName.
  ///
  /// In en, this message translates to:
  /// **'Exam name'**
  String get examName;

  /// No description provided for @examNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Half Yearly 2026'**
  String get examNameHint;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @classesAndSections.
  ///
  /// In en, this message translates to:
  /// **'Classes & Sections'**
  String get classesAndSections;

  /// No description provided for @class_.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get class_;

  /// No description provided for @sections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sections;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @questionCount.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get questionCount;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @marksPerCorrect.
  ///
  /// In en, this message translates to:
  /// **'Marks per correct answer'**
  String get marksPerCorrect;

  /// No description provided for @negativeMarking.
  ///
  /// In en, this message translates to:
  /// **'Negative marking'**
  String get negativeMarking;

  /// No description provided for @penaltyPerWrong.
  ///
  /// In en, this message translates to:
  /// **'Penalty per wrong answer'**
  String get penaltyPerWrong;

  /// No description provided for @paperHasSets.
  ///
  /// In en, this message translates to:
  /// **'This paper has different sets'**
  String get paperHasSets;

  /// No description provided for @set_.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set_;

  /// No description provided for @addAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'Add answer key'**
  String get addAnswerKey;

  /// No description provided for @answerKeyAdded.
  ///
  /// In en, this message translates to:
  /// **'Answer key added ✓'**
  String get answerKeyAdded;

  /// No description provided for @answerKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Key missing'**
  String get answerKeyMissing;

  /// No description provided for @scanOMR.
  ///
  /// In en, this message translates to:
  /// **'Scan OMR'**
  String get scanOMR;

  /// No description provided for @paperSettings.
  ///
  /// In en, this message translates to:
  /// **'Paper settings'**
  String get paperSettings;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out? Your local data stays on this device.'**
  String get logOutConfirm;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'You\'re using MasterJi as a guest'**
  String get guestMode;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get planFree;

  /// No description provided for @planPremium.
  ///
  /// In en, this message translates to:
  /// **'👑 Premium'**
  String get planPremium;

  /// No description provided for @unlimitedScansShort.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scans · Exams unlocked'**
  String get unlimitedScansShort;

  /// No description provided for @freeScansProgress.
  ///
  /// In en, this message translates to:
  /// **'{used} of 20 free scans used'**
  String freeScansProgress(int used);

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @schoolHint.
  ///
  /// In en, this message translates to:
  /// **'Your school name (optional)'**
  String get schoolHint;

  /// No description provided for @editSchool.
  ///
  /// In en, this message translates to:
  /// **'Edit school'**
  String get editSchool;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @helpAndShare.
  ///
  /// In en, this message translates to:
  /// **'Help & Share'**
  String get helpAndShare;

  /// No description provided for @whatsappSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp support'**
  String get whatsappSupport;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get shareApp;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate app'**
  String get rateApp;

  /// No description provided for @aboutAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'About & privacy'**
  String get aboutAndPrivacy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @notifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get notifyMe;

  /// No description provided for @wellLetYouKnow.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know!'**
  String get wellLetYouKnow;

  /// No description provided for @lessonPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Personalised lesson plans for your class, coming soon.'**
  String get lessonPlansDescription;

  /// No description provided for @whichSubjectMost.
  ///
  /// In en, this message translates to:
  /// **'Which do you need most?'**
  String get whichSubjectMost;

  /// No description provided for @noExamsYet.
  ///
  /// In en, this message translates to:
  /// **'No exams yet'**
  String get noExamsYet;

  /// No description provided for @createFirstExam.
  ///
  /// In en, this message translates to:
  /// **'Create your first exam'**
  String get createFirstExam;

  /// No description provided for @tryQuickScanInstead.
  ///
  /// In en, this message translates to:
  /// **'Try Quick Scan instead'**
  String get tryQuickScanInstead;

  /// No description provided for @checkOMRInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Check OMR sheets in seconds'**
  String get checkOMRInSeconds;

  /// No description provided for @loginBanner.
  ///
  /// In en, this message translates to:
  /// **'Log in with Google to keep your account safe'**
  String get loginBanner;

  /// No description provided for @quickScanInProgress.
  ///
  /// In en, this message translates to:
  /// **'Quick Scan in progress'**
  String get quickScanInProgress;

  /// No description provided for @continueCurrentKey.
  ///
  /// In en, this message translates to:
  /// **'Continue with the current answer key?'**
  String get continueCurrentKey;

  /// No description provided for @startNew.
  ///
  /// In en, this message translates to:
  /// **'Start new'**
  String get startNew;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @saveAsExam.
  ///
  /// In en, this message translates to:
  /// **'Save as an exam'**
  String get saveAsExam;

  /// No description provided for @filledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {total} filled'**
  String filledCount(int count, int total);

  /// No description provided for @jumpToQuestion.
  ///
  /// In en, this message translates to:
  /// **'Jump to question'**
  String get jumpToQuestion;

  /// No description provided for @nowScanningSet.
  ///
  /// In en, this message translates to:
  /// **'Now scanning {set}'**
  String nowScanningSet(String set);

  /// No description provided for @noAnswerKey.
  ///
  /// In en, this message translates to:
  /// **'No answer key added yet'**
  String get noAnswerKey;

  /// No description provided for @addAnswerKeyFirst.
  ///
  /// In en, this message translates to:
  /// **'Add the answer key before scanning'**
  String get addAnswerKeyFirst;

  /// No description provided for @debugSection.
  ///
  /// In en, this message translates to:
  /// **'Debug panel (dev only)'**
  String get debugSection;

  /// No description provided for @resetFreeScans.
  ///
  /// In en, this message translates to:
  /// **'Reset free scans to 20'**
  String get resetFreeScans;

  /// No description provided for @isLoggedInMock.
  ///
  /// In en, this message translates to:
  /// **'Logged in (mock)'**
  String get isLoggedInMock;

  /// No description provided for @isPremiumMock.
  ///
  /// In en, this message translates to:
  /// **'Premium (mock)'**
  String get isPremiumMock;

  /// No description provided for @subjectCount.
  ///
  /// In en, this message translates to:
  /// **'{count} subjects'**
  String subjectCount(int count);

  /// No description provided for @answerKeysProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} answer keys added'**
  String answerKeysProgress(int done, int total);

  /// No description provided for @recentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get recentlyUsed;

  /// No description provided for @startScanning.
  ///
  /// In en, this message translates to:
  /// **'Start scanning'**
  String get startScanning;

  /// No description provided for @selectExam.
  ///
  /// In en, this message translates to:
  /// **'Select exam'**
  String get selectExam;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select subject'**
  String get selectSubject;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select class & section'**
  String get selectClass;

  /// No description provided for @selectSet.
  ///
  /// In en, this message translates to:
  /// **'Select set'**
  String get selectSet;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String confirmDeleteTitle(String name);

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmDeleteBody;

  /// No description provided for @successExamCreated.
  ///
  /// In en, this message translates to:
  /// **'Exam created!'**
  String get successExamCreated;

  /// No description provided for @noSheetsYet.
  ///
  /// In en, this message translates to:
  /// **'No sheets scanned yet'**
  String get noSheetsYet;

  /// No description provided for @free20Left.
  ///
  /// In en, this message translates to:
  /// **'20 free scans left'**
  String get free20Left;

  /// No description provided for @used20Scans.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your 20 free scans. Go Premium to keep scanning and create exams.'**
  String get used20Scans;

  /// No description provided for @odia.
  ///
  /// In en, this message translates to:
  /// **'ଓଡ଼ିଆ'**
  String get odia;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @tapToSwitch.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch language any time in Profile'**
  String get tapToSwitch;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class {num}'**
  String classLabel(int num);

  /// No description provided for @sectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Section {letter}'**
  String sectionLabel(String letter);

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {letter}'**
  String setLabel(String letter);

  /// No description provided for @paperLabel.
  ///
  /// In en, this message translates to:
  /// **'{subject} · Class {classNum}'**
  String paperLabel(String subject, int classNum);

  /// No description provided for @oriya.
  ///
  /// In en, this message translates to:
  /// **'Odia'**
  String get oriya;

  /// No description provided for @math.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get math;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @socialScience.
  ///
  /// In en, this message translates to:
  /// **'Social Science'**
  String get socialScience;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @sanskrit.
  ///
  /// In en, this message translates to:
  /// **'Sanskrit'**
  String get sanskrit;

  /// No description provided for @english2.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english2;

  /// No description provided for @addOther.
  ///
  /// In en, this message translates to:
  /// **'Add other'**
  String get addOther;

  /// No description provided for @enterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter question number'**
  String get enterQuestion;

  /// No description provided for @privacyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'MasterJi respects your privacy. All your data is stored only on your device. No personal data is collected or shared with third parties.\n\nFor support, contact us on WhatsApp.'**
  String get privacyPlaceholder;

  /// No description provided for @classSectionSet.
  ///
  /// In en, this message translates to:
  /// **'{subject} · Class {classNum}-{section} · {set}'**
  String classSectionSet(
      String subject, int classNum, String section, String set);

  /// No description provided for @sheetsChecked.
  ///
  /// In en, this message translates to:
  /// **'{count} sheets checked'**
  String sheetsChecked(int count);

  /// No description provided for @scoreFormula.
  ///
  /// In en, this message translates to:
  /// **'{correct} × {marksPerCorrect} − {wrong} × {penalty} = {total}'**
  String scoreFormula(int correct, String marksPerCorrect, int wrong,
      String penalty, String total);

  /// No description provided for @examBenefitSets.
  ///
  /// In en, this message translates to:
  /// **'Sets A/B/C/D supported'**
  String get examBenefitSets;

  /// No description provided for @examBenefitClass.
  ///
  /// In en, this message translates to:
  /// **'Class & section wise'**
  String get examBenefitClass;

  /// No description provided for @lessonPlansComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get lessonPlansComingSoon;

  /// No description provided for @examBenefitKeys.
  ///
  /// In en, this message translates to:
  /// **'Save answer keys for every paper'**
  String get examBenefitKeys;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'or'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'or':
      return AppLocalizationsOr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
