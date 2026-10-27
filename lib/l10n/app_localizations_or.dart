// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oriya (`or`).
class AppLocalizationsOr extends AppLocalizations {
  AppLocalizationsOr([String locale = 'or']) : super(locale);

  @override
  String get appName => 'MasterJi';

  @override
  String get appTagline => 'ସେକେଣ୍ଡରେ OMR ସିଟ୍ ଯାଞ୍ଚ କରନ୍ତୁ';

  @override
  String get namaskar => 'ନମସ୍କାର';

  @override
  String namaskarName(String name) {
    return 'ନମସ୍କାର, $name';
  }

  @override
  String today(String date) {
    return 'ଆଜି, $date';
  }

  @override
  String get home => 'ହୋମ୍';

  @override
  String get exams => 'ପରୀକ୍ଷା';

  @override
  String get lessonPlans => 'ପାଠ ଯୋଜନା';

  @override
  String get profile => 'ପ୍ରୋଫାଇଲ୍';

  @override
  String get quickScan => 'କ୍ୱିକ୍ ସ୍କାନ୍';

  @override
  String get quickScanSubtitle =>
      'ଉତ୍ତର ସୂଚୀ ସ୍କାନ୍ କରନ୍ତୁ, ତା\'ପରେ ଛାତ୍ର ସିଟ୍। କୌଣସି ସଜ୍ଜ ନାହିଁ।';

  @override
  String get examsScanSubtitle => 'ପରୀକ୍ଷା ଅନୁସାରେ OMR ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get continueWithGoogle => 'Google ସହ ଆଗକୁ ବଢ଼ନ୍ତୁ';

  @override
  String get skipForNow => 'ବର୍ତ୍ତମାନ ଛାଡ଼ନ୍ତୁ';

  @override
  String get youGet20FreeScans => 'ଆପଣ 20ଟି ମାଗଣା ସ୍କାନ୍ ପାଇବେ';

  @override
  String freeScansLeft(int count) {
    return '$countଟି ବାକି ମାଗଣା ସ୍କାନ୍';
  }

  @override
  String get premiumBadge => 'ପ୍ରିମିୟମ୍';

  @override
  String get premium => 'ପ୍ରିମିୟମ୍';

  @override
  String get goPremium => 'ପ୍ରିମିୟମ୍ ନିନ୍ତୁ';

  @override
  String get premiumTitle => 'ପ୍ରିମିୟମ୍ ନିନ୍ତୁ';

  @override
  String get unlimitedScans => 'ଅସୀମ ସ୍କାନ୍';

  @override
  String get createExamsWithSets => 'ସେଟ୍ ସହ ପରୀକ୍ଷା ତିଆରି';

  @override
  String get classAndSectionResults => 'ଶ୍ରେଣୀ ଓ ବିଭାଗ ଅନୁସାରେ ଫଳ';

  @override
  String get monthly => 'ମାସିକ';

  @override
  String get yearly => 'ବାର୍ଷିକ';

  @override
  String get bestValue => 'ସର୍ବୋତ୍ତମ ମୂଲ୍ୟ';

  @override
  String get pay => 'ଦେୟ ଦିଅନ୍ତୁ';

  @override
  String get paymentsComingSoon => 'ଦେୟ ଶୀଘ୍ର ଆସୁଛି';

  @override
  String get maybeLater => 'ପରେ ହୁଏତ';

  @override
  String get continueWithGoogleToUpgrade =>
      'ଅପଗ୍ରେଡ୍ ପାଇଁ Google ସହ ଆଗକୁ ବଢ଼ନ୍ତୁ';

  @override
  String get scanAnswerKey => 'ଉତ୍ତର ସୂଚୀ ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get enterManually => 'ନିଜେ ଲଖନ୍ତୁ';

  @override
  String get useThisKey => 'ଏହି ଉତ୍ତର ସୂଚୀ ବ୍ୟବହାର କରନ୍ତୁ';

  @override
  String get nextSheet => 'ପରବର୍ତ୍ତୀ ସିଟ୍';

  @override
  String get rescanThisSheet => 'ଏହି ସିଟ୍ ଆଉଥରେ ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get finish => 'ସଂପୂର୍ଣ୍ଣ';

  @override
  String get correct => 'ଠିକ୍';

  @override
  String get wrong => 'ଭୁଲ୍';

  @override
  String get skipped => 'ଛାଡ଼ିଥିବା';

  @override
  String get marks => 'ନମ୍ବର';

  @override
  String get seeAnswers => 'ଉତ୍ତର ଦେଖନ୍ତୁ';

  @override
  String get hideAnswers => 'ଉତ୍ତର ଲୁଚାନ୍ତୁ';

  @override
  String get checking => 'ଯାଞ୍ଚ ହେଉଛି…';

  @override
  String sheetNumber(int number) {
    return 'ସିଟ୍ #$number';
  }

  @override
  String get continueScanning => 'ସ୍କାନ୍ ଜାରି ରଖନ୍ତୁ';

  @override
  String get clearSession => 'ସେସନ୍ ଖାଲି କରନ୍ତୁ';

  @override
  String get sessionSummary => 'ସେସନ୍ ସାରାଂଶ';

  @override
  String sheets(int count) {
    return '$countଟି ସିଟ୍';
  }

  @override
  String get average => 'ହାରାହାରି';

  @override
  String get highest => 'ସର୍ବାଧିକ';

  @override
  String get lowest => 'ସର୍ବନିମ୍ନ';

  @override
  String get mostMissed => 'ସବୁଠୁ ଅଧିକ ଭୁଲ ପ୍ରଶ୍ନ';

  @override
  String get createExam => 'ପରୀକ୍ଷା ତିଆରି';

  @override
  String get newExam => '+ ନୂଆ ପରୀକ୍ଷା';

  @override
  String get examName => 'ପରୀକ୍ଷାର ନାମ';

  @override
  String get examNameHint => 'ଯଥା: ଅର୍ଧ ବାର୍ଷିକ 2026';

  @override
  String get subjects => 'ବିଷୟ';

  @override
  String get subject => 'ବିଷୟ';

  @override
  String get classesAndSections => 'ଶ୍ରେଣୀ ଓ ବିଭାଗ';

  @override
  String get class_ => 'ଶ୍ରେଣୀ';

  @override
  String get sections => 'ବିଭାଗ';

  @override
  String get next => 'ପରବର୍ତ୍ତୀ';

  @override
  String get back => 'ପଛକୁ';

  @override
  String get save => 'ସେଭ୍ କରନ୍ତୁ';

  @override
  String get cancel => 'ବାଦ୍ ଦିଅନ୍ତୁ';

  @override
  String get delete => 'ଡିଲ୍ ​​ କରନ୍ତୁ';

  @override
  String get rename => 'ନାମ ବଦଳାନ୍ତୁ';

  @override
  String get questionCount => 'ପ୍ରଶ୍ନ ସଂଖ୍ୟା';

  @override
  String get custom => 'କଷ୍ଟମ୍';

  @override
  String get marksPerCorrect => 'ପ୍ରତି ଠିକ୍ ଉତ୍ତରରେ ନମ୍ବର';

  @override
  String get negativeMarking => 'ନକାରାତ୍ମକ ମୂଲ୍ୟାୟନ';

  @override
  String get penaltyPerWrong => 'ଭୁଲ ଉତ୍ତରରେ କ୍ଷୟ';

  @override
  String get paperHasSets => 'ଏହି ପ୍ରଶ୍ନପତ୍ରରେ ଭିନ୍ନ ସେଟ୍ ଅଛି';

  @override
  String get set_ => 'ସେଟ୍';

  @override
  String get addAnswerKey => 'ଉତ୍ତର ସୂଚୀ ଯୋଡ଼ନ୍ତୁ';

  @override
  String get answerKeyAdded => 'ଉତ୍ତର ସୂଚୀ ଯୋଡ଼ା ହୋଇଛି ✓';

  @override
  String get answerKeyMissing => 'ଉତ୍ତର ସୂଚୀ ନାହିଁ';

  @override
  String get scanOMR => 'OMR ସ୍କାନ୍ କରନ୍ତୁ';

  @override
  String get paperSettings => 'ପ୍ରଶ୍ନପତ୍ର ସଜ୍ଜ';

  @override
  String get logIn => 'ଲଗ୍ ଇନ୍ କରନ୍ତୁ';

  @override
  String get logOut => 'ଲଗ୍ ଆଉଟ୍';

  @override
  String get logOutConfirm =>
      'ଆପଣ ଲଗ୍ ଆଉଟ୍ ହେବାକୁ ଚାହୁଁଛନ୍ତି? ଆପଣଙ୍କ ତଥ୍ୟ ଏହି ଉପକରଣରେ ରହିବ।';

  @override
  String get guestMode => 'ଆପଣ MasterJi ଅତିଥି ଭାବରେ ବ୍ୟବହାର କରୁଛନ୍ତି';

  @override
  String get planFree => 'ମାଗଣା ଯୋଜନା';

  @override
  String get planPremium => '👑 ପ୍ରିମିୟମ୍';

  @override
  String get unlimitedScansShort => 'ଅସୀମ ସ୍କାନ୍ · ପରୀକ୍ଷା ଖୋଲା';

  @override
  String freeScansProgress(int used) {
    return '20ରୁ $usedଟି ମାଗଣା ସ୍କାନ୍ ବ୍ୟବହୃତ';
  }

  @override
  String get school => 'ବିଦ୍ୟାଳୟ';

  @override
  String get schoolHint => 'ଆପଣଙ୍କ ବିଦ୍ୟାଳୟର ନାମ (ଐଚ୍ଛିକ)';

  @override
  String get editSchool => 'ବିଦ୍ୟାଳୟ ସଂଶୋଧନ';

  @override
  String get language => 'ଭାଷା';

  @override
  String get helpAndShare => 'ସହାୟତା ଓ ଅଂଶୀଦାର';

  @override
  String get whatsappSupport => 'WhatsApp ସହାୟତା';

  @override
  String get shareApp => 'ଆପ୍ ଅଂଶୀଦାର';

  @override
  String get rateApp => 'ଆପ୍ ମୂଲ୍ୟାୟନ';

  @override
  String get aboutAndPrivacy => 'ବିଷୟରେ ଓ ଗୋପନୀୟତା';

  @override
  String get version => 'ସଂସ୍କରଣ';

  @override
  String get notifyMe => 'ମୋତେ ଜଣାନ୍ତୁ';

  @override
  String get wellLetYouKnow => 'ଆମେ ଆପଣଙ୍କୁ ଜଣାଇବୁ!';

  @override
  String get lessonPlansDescription =>
      'ଆପଣଙ୍କ ଶ୍ରେଣୀ ପାଇଁ ବ୍ୟକ୍ତିଗତ ପାଠ ଯୋଜନା, ଶୀଘ୍ର ଆସୁଛି।';

  @override
  String get whichSubjectMost => 'ଆପଣ ସର୍ବାଧିକ କଉଁ ବିଷୟ ଚାହୁଁଛନ୍ତି?';

  @override
  String get noExamsYet => 'ଏ ପର୍ଯ୍ୟନ୍ତ କୌଣସି ପରୀକ୍ଷା ନାହିଁ';

  @override
  String get createFirstExam => 'ପ୍ରଥମ ପରୀକ୍ଷା ତିଆରି କରନ୍ତୁ';

  @override
  String get tryQuickScanInstead => 'ବଦଳରେ କ୍ୱିକ୍ ସ୍କାନ୍ ବ୍ୟବହାର କରନ୍ତୁ';

  @override
  String get checkOMRInSeconds => 'ସେକେଣ୍ଡରେ OMR ସିଟ୍ ଯାଞ୍ଚ କରନ୍ତୁ';

  @override
  String get loginBanner =>
      'ଆପଣଙ୍କ ଆକାଉଣ୍ଟ ସୁରକ୍ଷିତ ରଖିବା ପାଇଁ Google ସହ ଲଗ୍ ଇନ୍ କରନ୍ତୁ';

  @override
  String get quickScanInProgress => 'କ୍ୱିକ୍ ସ୍କାନ୍ ଚାଲୁ ଅଛି';

  @override
  String get continueCurrentKey => 'ବର୍ତ୍ତମାନ ଉତ୍ତର ସୂଚୀ ସହ ଚାଲୁ ରଖିବେ?';

  @override
  String get startNew => 'ନୂଆ ଆରଂଭ';

  @override
  String get continue_ => 'ଚାଲୁ ରଖନ୍ତୁ';

  @override
  String get saveAsExam => 'ପରୀକ୍ଷା ଭାବରେ ସେଭ୍ କରନ୍ତୁ';

  @override
  String filledCount(int count, int total) {
    return '$count / $total ପୂରଣ';
  }

  @override
  String get jumpToQuestion => 'ପ୍ରଶ୍ନ ନଂ ଯାଆନ୍ତୁ';

  @override
  String nowScanningSet(String set) {
    return 'ଏବେ ସ୍କାନ୍ ହେଉଛି $set';
  }

  @override
  String get noAnswerKey => 'ଉତ୍ତର ସୂଚୀ ଯୋଡ଼ା ହୋଇ ନାହିଁ';

  @override
  String get addAnswerKeyFirst => 'ସ୍କାନ୍ ଆଗରୁ ଉତ୍ତର ସୂଚୀ ଯୋଡ଼ନ୍ତୁ';

  @override
  String get debugSection => 'ଡିବଗ୍ ପ୍ୟାନେଲ (dev only)';

  @override
  String get resetFreeScans => 'ମାଗଣା ସ୍କାନ୍ 20ରେ ଫେରାନ୍ତୁ';

  @override
  String get isLoggedInMock => 'ଲଗ୍ ଇନ୍ (mock)';

  @override
  String get isPremiumMock => 'ପ୍ରିମିୟମ୍ (mock)';

  @override
  String subjectCount(int count) {
    return '$countଟି ବିଷୟ';
  }

  @override
  String answerKeysProgress(int done, int total) {
    return '$totalରୁ $doneଟି ଉତ୍ତର ସୂଚୀ ଯୋଡ଼ା ହୋଇଛି';
  }

  @override
  String get recentlyUsed => 'ଚାଲୁ ରଖନ୍ତୁ';

  @override
  String get startScanning => 'ସ୍କାନ୍ ଆରଂଭ';

  @override
  String get selectExam => 'ପରୀକ୍ଷା ବାଛନ୍ତୁ';

  @override
  String get selectSubject => 'ବିଷୟ ବାଛନ୍ତୁ';

  @override
  String get selectClass => 'ଶ୍ରେଣୀ ଓ ବିଭାଗ ବାଛନ୍ତୁ';

  @override
  String get selectSet => 'ସେଟ୍ ବାଛନ୍ତୁ';

  @override
  String get gallery => 'ଗ୍ୟାଲେରି';

  @override
  String confirmDeleteTitle(String name) {
    return '\"$name\" ଡିଲ୍ ​​ କରିବେ?';
  }

  @override
  String get confirmDeleteBody => 'ଏହି କାର୍ଯ୍ୟ ଅପ୍ରତ୍ୟାହାରଯୋଗ୍ୟ।';

  @override
  String get successExamCreated => 'ପରୀକ୍ଷା ତିଆରି ହୋଇଛି!';

  @override
  String get noSheetsYet => 'ଏ ପର୍ଯ୍ୟନ୍ତ କୌଣସି ସିଟ୍ ସ୍କାନ୍ ହୋଇ ନାହିଁ';

  @override
  String get free20Left => '20ଟି ମାଗଣା ସ୍କାନ୍ ବାକି';

  @override
  String get used20Scans =>
      'ଆପଣ 20ଟି ମାଗଣା ସ୍କାନ୍ ବ୍ୟବହାର କଲେ। ସ୍କାନ୍ ଜାରି ରଖିବା ଓ ପରୀକ୍ଷା ତିଆରି ପାଇଁ ପ୍ରିମିୟମ୍ ନିନ୍ତୁ।';

  @override
  String get odia => 'ଓଡ଼ିଆ';

  @override
  String get english => 'English';

  @override
  String get chooseLanguage => 'ଆପଣଙ୍କ ଭାଷା ବାଛନ୍ତୁ';

  @override
  String get tapToSwitch => 'ଭବିଷ୍ୟତରେ ପ୍ରୋଫାଇଲ୍‌ରୁ ଭାଷା ବଦଳାନ୍ତୁ';

  @override
  String classLabel(int num) {
    return 'ଶ୍ରେଣୀ $num';
  }

  @override
  String sectionLabel(String letter) {
    return 'ବିଭାଗ $letter';
  }

  @override
  String setLabel(String letter) {
    return 'ସେଟ୍ $letter';
  }

  @override
  String paperLabel(String subject, int classNum) {
    return '$subject · ଶ୍ରେଣୀ $classNum';
  }

  @override
  String get oriya => 'ଓଡ଼ିଆ';

  @override
  String get math => 'ଗଣିତ';

  @override
  String get science => 'ବିଜ୍ଞାନ';

  @override
  String get socialScience => 'ସାମାଜିକ ବିଜ୍ଞାନ';

  @override
  String get hindi => 'ହିନ୍ଦୀ';

  @override
  String get sanskrit => 'ସଂସ୍କୃତ';

  @override
  String get english2 => 'ଇଂରାଜୀ';

  @override
  String get addOther => 'ଅନ୍ୟ ଯୋଡ଼ନ୍ତୁ';

  @override
  String get enterQuestion => 'ପ୍ରଶ୍ନ ନଂ ଦିଅନ୍ତୁ';

  @override
  String get privacyPlaceholder =>
      'MasterJi ଆପଣଙ୍କ ଗୋପନୀୟତାକୁ ସମ୍ମାନ ଦିଏ। ଆପଣଙ୍କ ସମସ୍ତ ତଥ୍ୟ କେବଳ ଆପଣଙ୍କ ଉପକରଣରେ ସଞ୍ଚୟ ଥାଏ।\n\nସହାୟତା ପାଇଁ WhatsApp-ରେ ଯୋଗାଯୋଗ କରନ୍ତୁ।';

  @override
  String classSectionSet(
      String subject, int classNum, String section, String set) {
    return '$subject · ଶ୍ରେଣୀ $classNum-$section · $set';
  }

  @override
  String sheetsChecked(int count) {
    return '$countଟି ସିଟ୍ ଯାଞ୍ଚ ହୋଇଛି';
  }

  @override
  String scoreFormula(int correct, String marksPerCorrect, int wrong,
      String penalty, String total) {
    return '$correct × $marksPerCorrect − $wrong × $penalty = $total';
  }

  @override
  String get examBenefitSets => 'ସେଟ୍ A/B/C/D ସମର୍ଥିତ';

  @override
  String get examBenefitClass => 'ଶ୍ରେଣୀ ଓ ବିଭାଗ ଅନୁସାରେ';

  @override
  String get lessonPlansComingSoon => 'ଶୀଘ୍ର ଆସୁଛି';

  @override
  String get examBenefitKeys => 'ପ୍ରତ୍ୟେକ ପ୍ରଶ୍ନପତ୍ରର ଉତ୍ତର ସୂଚୀ ସଞ୍ଚୟ';
}
