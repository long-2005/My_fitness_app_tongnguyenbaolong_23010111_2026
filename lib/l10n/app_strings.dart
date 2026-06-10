import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/data/repositories/language_repository.dart';

/// Usage: AppStrings.of(context).signIn
class AppStrings {
  final String languageCode;
  const AppStrings._(this.languageCode);

  static AppStrings of(BuildContext context) {
    final code = Provider.of<LanguageService>(context, listen: false).languageCode;
    return AppStrings._(code);
  }

  bool get _vi => languageCode == LanguageService.langVi;

  // ── Auth ─────────────────────────────────────────────────────────────────
  String get welcomeTo => _vi ? 'Chào mừng đến với,' : 'Welcome To,';
  String get appName => 'The Onyx!';
  String get signIn => _vi ? 'Đăng nhập' : 'Sign in';
  String get signUp => _vi ? 'Đăng ký' : 'Sign Up';
  String get createAccount => _vi ? 'Tạo tài khoản' : 'Create Account';
  String get letsGo => _vi ? 'Bắt đầu' : 'Lets go';
  String get email => 'Email';
  String get password => _vi ? 'Mật khẩu' : 'Password';
  String get confirmPassword => _vi ? 'Xác nhận mật khẩu' : 'Confirm Password';
  String get fullName => _vi ? 'Họ và tên' : 'Full Name';
  String get noAccount =>
      _vi ? 'Chưa có tài khoản? ' : "Don't have an account? ";
  String get alreadyHaveAccount =>
      _vi ? 'Đã có tài khoản? ' : 'Already have an account? ';
  String get signInHere => _vi ? 'Đăng nhập' : 'Sign In';
  String get accountCreatedSuccess =>
      _vi ? 'Tạo tài khoản thành công!' : 'Account created successfully!';
  String get forgotPassword => _vi ? 'Quên mật khẩu?' : 'Forgot Password?';
  String get forgotPasswordTitle => _vi ? 'Quên mật khẩu' : 'Forgot Password';
  String get forgotPasswordSubtitle =>
      _vi
          ? 'Nhập email đã đăng ký, chúng tôi sẽ gửi link đặt lại mật khẩu.'
          : 'Enter your registered email and we will send you a reset link.';
  String get sendResetLink => _vi ? 'Gửi link đặt lại' : 'Send Reset Link';
  String get resetEmailSent =>
      _vi
          ? 'Đã gửi email đặt lại mật khẩu! Vui lòng kiểm tra hộp thư.'
          : 'Password reset email sent! Please check your inbox.';
  String get backToSignIn => _vi ? 'Quay lại đăng nhập' : 'Back to Sign In';

  // ── Validation ───────────────────────────────────────────────────────────
  String get pleaseEnterEmail =>
      _vi ? 'Vui lòng nhập email' : 'Please enter your email';
  String get invalidEmail =>
      _vi ? 'Email không hợp lệ' : 'Please enter a valid email';
  String get pleaseEnterPassword =>
      _vi ? 'Vui lòng nhập mật khẩu' : 'Please enter your password';
  String get passwordTooShort =>
      _vi
          ? 'Mật khẩu phải ít nhất 6 ký tự'
          : 'Password must be at least 6 characters';
  String get pleaseEnterName =>
      _vi ? 'Vui lòng nhập họ tên' : 'Please enter your full name';
  String get nameTooShort =>
      _vi ? 'Tên quá ngắn' : 'Name is too short';
  String get pleaseConfirmPassword =>
      _vi ? 'Vui lòng xác nhận mật khẩu' : 'Please confirm your password';
  String get passwordsDoNotMatch =>
      _vi ? 'Mật khẩu không khớp' : 'Passwords do not match';

  // ── Home ──────────────────────────────────────────────────────────────────
  String get welcomeBack => _vi ? 'Xin chào,' : 'Welcome back,';
  String get homeTab => _vi ? 'Trang chủ' : 'Home';
  String get bmiTab => 'BMI & TDEE';
  String get caloTab => _vi ? 'Calo' : 'Calo Track';
  String get scheduleTab => _vi ? 'Lịch tập' : 'Schedule';
  String get latestMetrics => _vi ? 'Chỉ số mới nhất' : 'Latest metrics';
  String get updateBmiTdee => _vi ? 'Cập nhật BMI & TDEE' : 'Update BMI & TDEE';
  String get today => _vi ? 'Hôm nay' : 'Today';
  String get openTracker => _vi ? 'Mở bộ theo dõi' : 'Open tracker';
  String get noFoodsLogged =>
      _vi ? 'Chưa có thức ăn nào hôm nay.' : 'No foods logged today.';
  String get addBmiPrompt =>
      _vi
          ? 'Thêm BMI & TDEE để so sánh với mục tiêu calo.'
          : 'Add BMI & TDEE to compare against your calorie goal.';
  String get updatedFromRecord =>
      _vi
          ? 'Cập nhật từ bản ghi sức khỏe mới nhất.'
          : 'Updated from your most recent health record.';
  String get notSignedIn => _vi ? 'Chưa đăng nhập' : 'Not signed in';
  String get signInToSeeMetrics =>
      _vi
          ? 'Đăng nhập để xem BMI, TDEE và các chỉ số sức khỏe.'
          : 'Sign in to display your BMI, TDEE, and latest health records on the Home page.';
  String get dailyMealLocked =>
      _vi ? 'Bảng bữa ăn chưa mở khóa' : 'Daily meal dashboard locked';
  String get signInToSeeMeals =>
      _vi
          ? 'Đăng nhập để xem bữa ăn và calo hôm nay.'
          : "Sign in to display today's meals, calories, and quick nutrition overview.";
  String get noBmiData => _vi ? 'Chưa có dữ liệu BMI' : 'No BMI data yet';
  String get openBmiTab => _vi ? 'Mở tab BMI' : 'Open BMI tab';
  String get noBmiDataMessage =>
      _vi
          ? 'Mở tab BMI & TDEE để tính và lưu bản ghi đầu tiên của bạn. Chỉ số mới nhất sẽ hiển thị ở đây.'
          : 'Open the BMI & TDEE tab to calculate and save your first record. Your latest metrics will appear here afterward.';

  // ── Drawer ────────────────────────────────────────────────────────────────
  String get settings => _vi ? 'Cài đặt' : 'Settings';
  String get helpSupport => _vi ? 'Trợ giúp & Hỗ trợ' : 'Help & Support';
  String get signOut => _vi ? 'Đăng xuất' : 'Sign Out';
  String get signOutConfirmTitle => _vi ? 'Đăng xuất' : 'Sign Out';
  String get signOutConfirmMessage =>
      _vi
          ? 'Bạn có chắc chắn muốn đăng xuất không?'
          : 'Are you sure you want to sign out?';
  String get cancel => _vi ? 'Hủy' : 'Cancel';
  String get confirm => _vi ? 'Xác nhận' : 'Confirm';
  String get helpComingSoon =>
      _vi ? 'Tính năng trợ giúp đang phát triển.' : 'Help feature coming soon.';

  // ── BMI ───────────────────────────────────────────────────────────────────
  String get bmiTrackerTitle => _vi ? 'Theo dõi BMI & TDEE' : 'BMI & TDEE Tracker';
  String get yourLatestMetrics =>
      _vi ? 'Chỉ số cơ thể mới nhất' : 'Your latest body metrics';
  String get trackYourBmi =>
      _vi ? 'Theo dõi BMI & calo của bạn' : 'Track your BMI and calories';
  String get enterInfoBelow =>
      _vi
          ? 'Nhập thông tin bên dưới để tính toán và lưu chỉ số sức khỏe.'
          : 'Enter your information below to calculate, save, and review your health indicators.';
  String get waitingForData => _vi ? 'Đang chờ dữ liệu' : 'Waiting for data';
  String get measurementHistory =>
      _vi ? 'Lịch sử đo lường' : 'Measurement History';
  String get recordSaved =>
      _vi ? 'Đã lưu bản ghi thành công!' : 'Record saved successfully!';
  String get weightKg => _vi ? 'Cân nặng (kg)' : 'Weight (kg)';
  String get heightCm => _vi ? 'Chiều cao (cm)' : 'Height (cm)';
  String get age => _vi ? 'Tuổi' : 'Age';
  String get gender => _vi ? 'Giới tính' : 'Gender';
  String get male => _vi ? 'Nam' : 'Male';
  String get female => _vi ? 'Nữ' : 'Female';
  String get activityLevel => _vi ? 'Mức độ hoạt động' : 'Activity Level';
  String get calculateAndSave =>
      _vi ? 'Tính toán & Lưu bản ghi' : 'Calculate & Save Record';
  String get noDataFound =>
      _vi
          ? 'Chưa có dữ liệu.\nNhập thông tin để bắt đầu theo dõi.'
          : 'No data found.\nPlease enter your info to start tracking.';
  String get signInToSyncHistory =>
      _vi ? 'Đăng nhập để đồng bộ lịch sử.' : 'Please sign in to sync history.';
  String get couldNotLoadHistory =>
      _vi ? 'Không thể tải lịch sử đo lường.' : 'Could not load measurement history.';

  List<String> get activityOptions => _vi
      ? [
          'Ít vận động (ngồi văn phòng)',
          'Nhẹ nhàng (1-3 ngày/tuần)',
          'Vừa phải (3-5 ngày/tuần)',
          'Năng động (6-7 ngày/tuần)',
          'Rất năng động (2 lần/ngày)',
        ]
      : [
          'Sedentary (office job)',
          'Lightly active (1-3 days/week)',
          'Moderately active (3-5 days/week)',
          'Very active (6-7 days/week)',
          'Extra active (twice a day)',
        ];

  List<String> get genderOptions => _vi ? ['Nam', 'Nữ'] : ['Male', 'Female'];

  // ── Calo Tracking ─────────────────────────────────────────────────────────
  String get caloTrackingTitle =>
      _vi ? 'Theo dõi Calo' : 'Calorie Tracking';
  String get searchFood => _vi ? 'Tìm kiếm thực phẩm' : 'Search food';
  String get addFood => _vi ? 'Thêm thực phẩm' : 'Add Food';
  String get createCustomDish =>
      _vi ? 'Tạo món ăn tùy chỉnh' : 'Create custom dish';
  String get save => _vi ? 'Lưu' : 'Save';
  String get delete => _vi ? 'Xóa' : 'Delete';
  String get calories => _vi ? 'Calo' : 'Calories';
  String get protein => _vi ? 'Đạm' : 'Protein';
  String get fat => _vi ? 'Chất béo' : 'Fat';
  String get carbs => _vi ? 'Tinh bột' : 'Carbs';
  String get breakfast => _vi ? 'Bữa sáng' : 'Breakfast';
  String get lunch => _vi ? 'Bữa trưa' : 'Lunch';
  String get dinner => _vi ? 'Bữa tối' : 'Dinner';
  String get snack => _vi ? 'Ăn vặt' : 'Snack';
  String get noResultsFound =>
      _vi ? 'Không tìm thấy kết quả.' : 'No results found.';
  String get pleaseAddIngredient =>
      _vi ? 'Vui lòng thêm ít nhất một nguyên liệu' : 'Please add at least one ingredient';
  String get customDishSaved =>
      _vi ? 'Đã lưu món ăn tùy chỉnh' : 'Custom dish saved';
  String get addIngredientFromDb =>
      _vi ? 'Thêm từ cơ sở dữ liệu' : 'Add from database';
  String get manualIngredient =>
      _vi ? 'Nhập tay nguyên liệu' : 'Manual ingredient';

  // ── Schedule ─────────────────────────────────────────────────────────────
  String get trainingSchedule =>
      _vi ? 'Lịch tập luyện' : 'Training Schedule';
  String get resetWeek => _vi ? 'Đặt lại tuần' : 'Reset week';
  String get sessions => _vi ? 'Buổi tập' : 'Sessions';
  String get muscles => _vi ? 'Cơ bắp' : 'Muscles';
  String get daysPerWeek => _vi ? 'ngày/tuần' : 'days/week';
  String get groupsHit => _vi ? 'nhóm luyện' : 'groups hit';
  String get weeklyMuscleHeat =>
      _vi ? 'Nhiệt độ cơ bắp tuần' : 'Weekly muscle heat';
  String get createWorkoutPlan =>
      _vi ? 'Tạo kế hoạch tập luyện' : 'Create workout plan';
  String get noWorkoutPlanned =>
      _vi ? 'Không có bài tập cho ngày này.' : 'No workout planned for this day.';
  String get searchExercise =>
      _vi ? 'Tìm bài tập...' : 'Search exercises...';
  String get noExercisesMatch =>
      _vi ? 'Không tìm thấy bài tập.' : 'No exercises match this search.';
  String get searchOrFilter =>
      _vi
          ? 'Tìm theo tên hoặc dùng bộ lọc để tìm bài tập.'
          : 'Search by name or use the filter button to find exercises.';
  String get weeklyBreakdown =>
      _vi ? 'Phân tích tuần' : 'Weekly Breakdown';
  String get startSession => _vi ? 'Bắt đầu buổi tập' : 'Start Session';
  String get restDay => _vi ? 'Ngày nghỉ' : 'Rest Day';

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settingsTitle => _vi ? 'Cài đặt' : 'Settings';
  String get languageSectionTitle => _vi ? 'Ngôn ngữ' : 'Language';
  String get languageEnglish => 'English';
  String get languageVietnamese => 'Tiếng Việt';
  String get appearanceSectionTitle =>
      _vi ? 'Giao diện' : 'Appearance';
  String get comingSoon => _vi ? 'Sắp ra mắt' : 'Coming soon';
  String get accountSectionTitle => _vi ? 'Tài khoản' : 'Account';
  String get signOutFromSettings =>
      _vi ? 'Đăng xuất khỏi tài khoản' : 'Sign out of your account';

  // ── Progress ──────────────────────────────────────────────────────────────
  String get progressTab => _vi ? 'Tiến trình' : 'Progress';
  String get progressTitle => _vi ? 'Tiến trình của bạn' : 'Your Progress';
  String get workoutHistory => _vi ? 'Lịch sử tập luyện' : 'Workout History';
  String get noWorkoutHistory =>
      _vi
          ? 'Chưa có buổi tập nào.\nHãy bắt đầu buổi tập đầu tiên!'
          : 'No workouts yet.\nStart your first session!';
  String get totalSessions => _vi ? 'Tổng buổi tập' : 'Total Sessions';
  String get workoutStreak => _vi ? 'Streak hiện tại' : 'Current Streak';
  String get daysLabel => _vi ? 'ngày' : 'days';
  String get sessionsLabel => _vi ? 'buổi' : 'sessions';
  String get thisWeek => _vi ? 'Tuần này' : 'This week';
  String get weightProgress => _vi ? 'Cân nặng theo thời gian' : 'Weight over time';
  String get calorieWeek => _vi ? 'Calo 7 ngày gần nhất' : 'Last 7 days calories';
  String get noProgressData =>
      _vi
          ? 'Chưa có dữ liệu.\nHãy nhập BMI để bắt đầu theo dõi.'
          : 'No data yet.\nAdd a BMI record to start tracking.';
  String get signInToSeeProgress =>
      _vi
          ? 'Đăng nhập để xem tiến trình của bạn.'
          : 'Sign in to see your progress.';
}

