import 'dart:math' as Math;

class KmaCoordinateConverter {
  // ----------------------------------------------------
  // LCC DFS 좌표변환을 위한 기초 자료 (기상청 공식 상수를 사용)
  // ----------------------------------------------------
  static const double RE = 6371.00877; // 지구 반경(km)
  static const double GRID = 5.0; // 격자 간격(km)
  static const double SLAT1 = 30.0; // 투영 위도1(degree)
  static const double SLAT2 = 60.0; // 투영 위도2(degree)
  static const double OLON = 126.0; // 기준점 경도(degree)
  static const double OLAT = 38.0; // 기준점 위도(degree)
  static const double XO = 43.0; // 기준점 X좌표(GRID)
  static const double YO = 136.0; // 기준점 Y좌표(GRID)
  // ----------------------------------------------------

  static const double DEGRAD = Math.pi / 180.0;
  static const double RADDEG = 180.0 / Math.pi;

  static Map<String, int> convert(double lat, double lng) {
    // 내부 계산을 위한 상수 정의
    final re = RE / GRID;
    final slat1 = SLAT1 * DEGRAD;
    final slat2 = SLAT2 * DEGRAD;
    final olon = OLON * DEGRAD;
    final olat = OLAT * DEGRAD;

    // 변환에 필요한 상수 계산
    var snTmp = Math.tan(Math.pi * 0.25 + slat2 * 0.5) /
        Math.tan(Math.pi * 0.25 + slat1 * 0.5);
    final sn =
        Math.log(Math.cos(slat1) / Math.cos(slat2)) / Math.log(snTmp);

    var sfTmp = Math.tan(Math.pi * 0.25 + slat1 * 0.5);
    final sf = Math.pow(sfTmp, sn) * Math.cos(slat1) / sn;

    var roTmp = Math.tan(Math.pi * 0.25 + olat * 0.5);
    final ro = re * sf / Math.pow(roTmp, sn);

    // ----------------------------------------------------
    // LCC DFS GPS -> GRID (위경도 -> 격자 좌표) 로직 시작
    // ----------------------------------------------------

    var ra = Math.tan(Math.pi * 0.25 + (lat) * DEGRAD * 0.5);
    ra = re * sf / Math.pow(ra, sn);

    var theta = lng * DEGRAD - olon;
    if (theta > Math.pi) theta -= 2.0 * Math.pi;
    if (theta < -Math.pi) theta += 2.0 * Math.pi;
    theta *= sn;

    // 격자 좌표 계산 및 반올림 처리
    final int nx = (ra * Math.sin(theta) + XO + 0.5).floor();
    final int ny = (ro - ra * Math.cos(theta) + YO + 0.5).floor();

    // ----------------------------------------------------

    return {
      'nx': nx,
      'ny': ny,
    };
  }
}