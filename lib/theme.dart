import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 뉴스 알리미 디자인 토큰 (ChatGPT 시안 'Modern News Monitor' 기준).
///
/// 모든 색상·폰트·크기는 이 파일에만 둔다. 위젯 코드에서 색상 hex를
/// 직접 하드코딩하지 않는다.
///
/// 참고: 시안은 Pretendard 폰트를 지정했지만, Pretendard는 Google Fonts에
/// 없어 google_fonts 패키지로 불러올 수 없다. v1에서는 Google Fonts의
/// Noto Sans KR을 적용했다. Pretendard TTF를 로컬에 등록하면 이 파일의
/// GoogleFonts 호출만 Pretendard로 바꾸면 된다.
class AppColors {
  AppColors._();

  // Primary
  static const Color primaryLight = Color(0xFF246BCE);
  static const Color primaryDark = Color(0xFF6BA8FF);

  // Background
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121923);

  // Surface (카드)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C2735);

  // 카드 테두리
  static const Color borderLight = Color(0xFFE4E9F0);
  static const Color borderDark = Color(0xFF344154);

  // 기본 글자
  static const Color textPrimaryLight = Color(0xFF172B4D);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);

  // 보조 글자
  static const Color textSecondaryLight = Color(0xFF667085);
  static const Color textSecondaryDark = Color(0xFF9BA9BC);

  // 키워드 강조
  static const Color highlightLight = Color(0xFFFFF0B3);
  static const Color highlightDark = Color(0xFF66521F);

  // 성공 / 새 뉴스
  static const Color successLight = Color(0xFF16845B);
  static const Color successDark = Color(0xFF55C99A);

  // 오류
  static const Color errorLight = Color(0xFFD64545);
  static const Color errorDark = Color(0xFFFF7777);

  // 입력창 (다크)
  static const Color inputDark = Color(0xFF202D3D);

  // 버튼 글자 (다크)
  static const Color onPrimaryDark = Color(0xFF10233D);

  // 입력창 테두리 (라이트)
  static const Color inputBorderLight = Color(0xFFD5DCE5);

  // 출처·시간 보조 회색 (라이트)
  static const Color metaGrayLight = Color(0xFF8993A2);

  // 키워드 태그 배경 (연한 파란색)
  static const Color tagBackgroundLight = Color(0xFFE8F0FE);
  static const Color tagBackgroundDark = Color(0xFF24344D);

  static Color primary(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : borderLight;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color highlight(Brightness brightness) =>
      brightness == Brightness.dark ? highlightDark : highlightLight;

  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : successLight;

  static Color error(Brightness brightness) =>
      brightness == Brightness.dark ? errorDark : errorLight;

  static Color onPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? onPrimaryDark : Colors.white;

  static Color inputFill(Brightness brightness) =>
      brightness == Brightness.dark ? inputDark : surfaceLight;

  static Color inputBorder(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : inputBorderLight;

  static Color meta(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : metaGrayLight;

  static Color tagBackground(Brightness brightness) =>
      brightness == Brightness.dark ? tagBackgroundDark : tagBackgroundLight;
}

/// 시안 규격: 앱 제목 22 Bold, 화면 제목 20 Bold, 카드 제목 16 SemiBold,
/// 본문 14 Regular, 보조 설명 12 Regular, 버튼 15 SemiBold,
/// 오늘의 매칭 수 32 Bold, 기사 제목 23 Bold, 기사 본문 16 (줄 간격 1.7),
/// 출처 13 SemiBold.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(
    Brightness brightness,
    double size,
    FontWeight weight, {
    double? height,
    Color? color,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? AppColors.textPrimary(brightness),
    );
  }

  static TextStyle appTitle(Brightness b) => _base(b, 22, FontWeight.w700);

  static TextStyle screenTitle(Brightness b) => _base(b, 20, FontWeight.w700);

  static TextStyle cardTitle(Brightness b) => _base(b, 16, FontWeight.w600);

  static TextStyle body(Brightness b) => _base(b, 14, FontWeight.w400);

  static TextStyle caption(Brightness b) =>
      _base(b, 12, FontWeight.w400, color: AppColors.textSecondary(b));

  static TextStyle button(Brightness b) =>
      _base(b, 15, FontWeight.w600, color: AppColors.onPrimary(b));

  static TextStyle summaryCount(Brightness b) =>
      _base(b, 32, FontWeight.w700, color: Colors.white);

  static TextStyle summaryLabel(Brightness b) =>
      _base(b, 14, FontWeight.w400, color: Colors.white);

  static TextStyle summarySub(Brightness b) =>
      _base(b, 12, FontWeight.w400, color: Colors.white70);

  static TextStyle articleTitle(Brightness b) =>
      _base(b, 23, FontWeight.w700, height: 1.4);

  static TextStyle articleBody(Brightness b) =>
      _base(b, 16, FontWeight.w400, height: 1.7);

  static TextStyle source(Brightness b) =>
      _base(b, 13, FontWeight.w600, color: AppColors.primary(b));

  static TextStyle count(Brightness b) =>
      _base(b, 14, FontWeight.w400, color: AppColors.primary(b));

  static TextStyle groupTitle(Brightness b) =>
      _base(b, 14, FontWeight.w400, color: AppColors.textSecondary(b));

  static TextStyle newBadge(Brightness b) =>
      _base(b, 11, FontWeight.w600, color: AppColors.success(b));

  static TextStyle meta(Brightness b) =>
      _base(b, 12, FontWeight.w400, color: AppColors.meta(b));

  static TextStyle tag(Brightness b) =>
      _base(b, 12, FontWeight.w500, color: AppColors.primary(b));
}

/// 시안 규격: 기본 좌우 여백 20dp, 카드 모서리 14dp, 버튼 높이 52dp,
/// 입력창 높이 56dp, 하단 내비게이션 72dp, 플로팅 버튼 56dp,
/// 최소 터치 영역 48x48dp.
class AppSizes {
  AppSizes._();

  static const double pagePadding = 20;
  static const double cardRadius = 14;
  static const double buttonHeight = 52;
  static const double inputHeight = 56;
  static const double bottomNavHeight = 72;
  static const double fabSize = 56;
  static const double appBarHeight = 60;
  static const double summaryCardHeight = 112;
  static const double keywordCardHeight = 76;
  static const double settingsRowHeight = 60;
  static const double keywordTagHeight = 28;
}

/// 라이트/다크 테마. ThemeMode.system을 기본으로 쓴다.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.errorLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: GoogleFonts.notoSansKrTextTheme(
        ThemeData.light().textTheme,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.onPrimaryDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.errorDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.notoSansKrTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}
