class WeatherDay {
  final DateTime date;

  String description;
  String iconCode;

  final int sky; // 1=맑음, 3=구름많음, 4=흐림
  final int pcp; // 강수량 코드(1~3, 0이면 없음)
  final int sno; // 적설 코드(1~2, 0이면 없음)

  double? currentTemp;
  double? minTemp;
  double? maxTemp;

  final int? rainProb; // 강수확률 %
  final double? rainAmount; // 강수량 mm

  WeatherDay({
    required this.description,
    required this.iconCode,
    required this.date,
    required this.sky,
    required this.pcp,
    required this.sno,
    this.currentTemp,
    this.minTemp,
    this.maxTemp,
    this.rainProb,
    this.rainAmount,
  });

  bool get isNight => date.hour >= 18 || date.hour < 6;

  String get skyText {
    switch (sky) {
      case 1:
        return "맑음";
      case 3:
        return "구름많음";
      case 4:
        return "흐림";
      default:
        return "알 수 없음";
    }
  }

  String get skyEmoji {
    switch (sky) {
      case 1:
        return isNight ? "🌙" : "☀️";
      case 3:
        return "⛅";
      case 4:
        return "☁️";
      default:
        return "🌈";
    }
  }

  String get pcpText {
    switch (pcp) {
      case 1:
        return "약한 비";
      case 2:
        return "보통 비";
      case 3:
        return "강한 비";
      default:
        return "";
    }
  }

  String get pcpEmoji {
    switch (pcp) {
      case 1:
        return "🌦️";
      case 2:
        return "🌧️";
      case 3:
        return "⛈️";
      default:
        return "";
    }
  }

  String get snoText {
    switch (sno) {
      case 1:
        return "보통 눈";
      case 2:
        return "많은 눈";
      default:
        return "";
    }
  }

  String get snoEmoji {
    switch (sno) {
      case 1:
        return "❄️";
      case 2:
        return "🌨️";
      default:
        return "";
    }
  }

  String get mainEmoji {
    if (sno > 0) return snoEmoji;
    if (pcp > 0) return pcpEmoji;
    return skyEmoji;
  }

  String get mainText {
    if (sno > 0) return snoText;
    if (pcp > 0) return pcpText;
    return skyText;
  }

  // 강수량 ↔ 강수확률 토글
  String rainDisplay({bool showProb = true}) {
    if (pcp == 0) return "";
    if (showProb && rainProb != null) return "☔${rainProb}%";
    if (!showProb && rainAmount != null) return "💧${rainAmount}mm";
    return pcpEmoji;
  }

  // 한 줄 요약
  String oneLineSummary({bool showRainProb = true}) {
    final rain = rainDisplay(showProb: showRainProb);

    final current = currentTemp != null
        ? "${currentTemp!.toStringAsFixed(0)}°"
        : '-';

    final max = maxTemp != null ? maxTemp!.toStringAsFixed(0) : '-';
    final min = minTemp != null ? minTemp!.toStringAsFixed(0) : '-';
    final maxMin = "${max}° / ${min}°";

    // 템플릿: 🌧️ | 11° | 14° / 7° | 💧2mm
    return [mainEmoji, current, maxMin, rain]
        .where((e) => e.isNotEmpty)
        .join(" | ");
  }
}