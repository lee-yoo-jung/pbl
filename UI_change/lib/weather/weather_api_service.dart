import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:pbl/weather/kma_coordinate_converter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pbl/weather/weather_day.dart';

String getWeatherApiKey() {
  return dotenv.env['WEATHER_API_KEY'] ?? 'API 키를 찾을 수 없습니다.';
}

class WeatherApiService {
  // --- API 엔드포인트 ---
  final String weatherApiKey = getWeatherApiKey();
  final String shortTermEndpoint = 'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst';
  final String midTermEndpoint = 'http://apis.data.go.kr/1360000/MidFcstInfoService/getMidLandFcst';

  final Map<String, String> KMA_REG_ID_MAP = {
    // ... (KMA_REG_ID_MAP는 변경 없음) ...
    // --- 수도권 (서울, 경기, 인천) ---
    '백령도': '11A00101',
    '과천': '11B10102',
    '광명': '11B10103',
    '강화': '11B20101',
    '김포': '11B20102',
    '인천': '11B20201',
    '시흥': '11B20202',
    '안산': '11B20203',
    '부천': '11B20204',
    '의정부': '11B20301',
    '고양': '11B20302',
    '양주': '11B20304',
    '파주': '11B20305',
    '동두천': '11B20401',
    '연천': '11B20402',
    '포천': '11B20403',
    '가평': '11B20404',
    '구리': '11B20501',
    '남양주': '11B20502',
    '양평': '11B20503',
    '하남': '11B20504',
    '수원': '11B20601',
    '안양': '11B20602',
    '오산': '11B20603',
    '화성': '11B20604',
    '성남': '11B20605',
    '평택': '11B20606',
    '의왕': '11B20609',
    '군포': '11B20610',
    '안성': '11B20611',
    '용인': '11B20612',
    '이천': '11B20701',
    '광주': '11B20702',
    '여주': '11B20703',

    // --- 충청북도 ---
    '충주': '11C10101',
    '진천': '11C10102',
    '음성': '11C10103',
    '제천': '11C10201',
    '단양': '11C10202',
    '청주': '11C10301',
    '보은': '11C10302',
    '괴산': '11C10303',
    '증평': '11C10304',
    '추풍령': '11C10401',
    '영동': '11C10402',
    '옥천': '11C10403',

    // --- 충청남도/대전/세종 ---
    '서산': '11C20101',
    '태안': '11C20102',
    '당진': '11C20103',
    '홍성': '11C20104',
    '보령': '11C20201',
    '서천': '11C20202',
    '천안': '11C20301',
    '아산': '11C20302',
    '예산': '11C20303',
    '대전': '11C20401',
    '공주': '11C20402',
    '계룡': '11C20403',
    '세종': '11C20404',
    '부여': '11C20501',
    '청양': '11C20502',
    '금산': '11C20601',
    '논산': '11C20602',

    // --- 강원도 ---
    '철원': '11D10101',
    '화천': '11D10102',
    '인제': '11D10201',
    '양구': '11D10202',
    '춘천': '11D10301',
    '홍천': '11D10302',
    '원주': '11D10401',
    '횡성': '11D10402',
    '영월': '11D10501',
    '정선': '11D10502',
    '평창': '11D10503',
    '대관령': '11D20201',
    '태백': '11D20301',
    '속초': '11D20401',
    '고성(강원)': '11D20402',
    '양양': '11D20403',
    '강릉': '11D20501',
    '동해': '11D20601',
    '삼척': '11D20602',

    // --- 섬 지역 (울릉도/독도) ---
    '울릉도': '11E00101',
    '독도': '11E00102',

    // --- 전라북도 ---
    '전주': '11F10201',
    '익산': '11F10202',
    '정읍': '11F10203',
    '완주': '11F10204',
    '장수': '11F10301',
    '무주': '11F10302',
    '진안': '11F10303',
    '남원': '11F10401',
    '임실': '11F10402',
    '순창': '11F10403',
    '군산': '21F10501',
    '김제': '21F10502',
    '고창': '21F10601',
    '부안': '21F10602',

    // --- 전라남도/광주 ---
    '함평': '21F20101',
    '영광': '21F20102',
    '진도': '21F20201',
    '완도': '11F20301',
    '해남': '11F20302',
    '강진': '11F20303',
    '장흥': '11F20304',
    '여수': '11F20401',
    '광양': '11F20402',
    '고흥': '11F20403',
    '보성': '11F20404',
    '순천시': '11F20405',
    '광주광역시': '11F20501',
    '장성': '11F20502',
    '나주': '11F20503',
    '담양': '11F20504',
    '화순': '11F20505',
    '구례': '11F20601',
    '곡성': '11F20602',
    '순천': '11F20603',
    '흑산도': '11F20701',
    '목포': '21F20801',
    '영암': '21F20802',
    '신안': '21F20803',
    '무안': '21F20804',

    // --- 제주도 ---
    '성산': '11G00101',
    '제주': '11G00201',
    '성판악': '11G00302',
    '서귀포': '11G00401',
    '고산': '11G00501',
    '이어도': '11G00601',
    '추자도': '11G00800',

    // --- 경상북도/대구 ---
    '울진': '11H10101',
    '영덕': '11H10102',
    '포항': '11H10201',
    '경주': '11H10202',
    '문경': '11H10301',
    '상주': '11H10302',
    '예천': '11H10303',
    '영주': '11H10401',
    '봉화': '11H10402',
    '영양': '11H10403',
    '안동': '11H10501',
    '의성': '11H10502',
    '청송': '11H10503',
    '김천': '11H10601',
    '구미': '11H10602',
    '군위': '11H10707',
    '고령': '11H10604',
    '성주': '11H10605',
    '대구': '11H10701',
    '영천': '11H10702',
    '경산': '11H10703',
    '청도': '11H10704',
    '칠곡': '11H10705',

    // --- 경상남도/부산/울산 ---
    '울산': '11H20101',
    '양산': '11H20102',
    '부산': '11H20201',
    '창원': '11H20301',
    '김해': '11H20304',
    '통영': '11H20401',
    '사천': '11H20402',
    '거제': '11H20403',
    '고성(경남)': '11H20404',
    '남해': '11H20405',
    '함양': '11H20501',
    '거창': '11H20502',
    '합천': '11H20503',
    '밀양': '11H20601',
    '의령': '11H20602',
    '함안': '11H20603',
    '창녕': '11H20604',
    '진주': '11H20701',
    '산청': '11H20703',
    '하동': '11H20704',

    // --- 북한 지역 ---
    '사리원': '11I10001',
    '신계': '11I10002',
    '해주': '11I20001',
    '개성': '11I20002',
    '장연(용연)': '11I20003',
    '신의주': '11J10001',
    '삭주(수풍)': '11J10002',
    '구성': '11J10003',
    '자성(중강)': '11J10004',
    '강계': '11J10005',
    '희천': '11J10006',
    '평양': '11J20001',
    '진남포(남포)': '11J20002',
    '안주': '11J20004',
    '양덕': '11J20005',
    '청진': '11K10001',
    '웅기(선봉)': '11K10002',
    '성진(김책)': '11K10003',
    '무산(삼지연)': '11K10004',
    '함흥': '11K20001',
    '장진': '11K20002',
    '북청(신포)': '11K20003',
    '혜산': '11K20004',
    '풍산': '11K20005',
    '원산': '11L10001',
    '고성(장전)': '11L10002',
    '평강': '11L10003',
  };

  // 중기 예보 API에서 요구하는 광역 코드를 반환하는 함수
  Future<String> _getRegId(double lat, double lon) async {
    const String seoulRegId = '11B10000';
    List<Placemark>? placemarks;

    // 1차 방어: Geocoding 서비스 자체 실패
    try {
      placemarks = await placemarkFromCoordinates(lat, lon);
    } catch (e) {
      print("Geocoding Service Error (Primary Catch): $e. Falling back to Seoul code.");
      return seoulRegId;
    }

    // placemarks가 null이거나 비어있을 때
    if (placemarks == null || placemarks.isEmpty) {
      print("Geocoding returned no result. Falling back to Seoul code.");
      return seoulRegId;
    }

    // 2차 방어: 주소 데이터 추출 시 Null Check Operator 오류 방어
    try {
      // placemarks[0].administrativeArea는 nullable일 수 있습니다.
      final adminArea = placemarks[0].administrativeArea;
      final adminAreaSafe = (adminArea ?? '').trim();

      if (adminAreaSafe.isEmpty) {
        print("Warning: administrativeArea is empty. Falling back to Seoul code.");
        return seoulRegId;
      }

      // 행정구역 이름 기반 광역 코드 결정 로직 (올바른 KMA 광역 코드 적용)
      if (adminAreaSafe.contains('서울') || adminAreaSafe.contains('경기') || adminAreaSafe.contains('인천')) {
        return '11B10000'; // 수도권 (서울/경기/인천)
      } else if (adminAreaSafe.contains('강원')) {
        return '11D10000'; // 강원도
      } else if (adminAreaSafe.contains('충북') || adminAreaSafe.contains('충청북도')) {
        return '11C10000'; // 충청북도
      } else if (adminAreaSafe.contains('충남') || adminAreaSafe.contains('충청남도') || adminAreaSafe.contains('대전') || adminAreaSafe.contains('세종')) {
        return '11C20000'; // 충청남도/대전/세종
      } else if (adminAreaSafe.contains('전북') || adminAreaSafe.contains('전라북도')) {
        return '11F10000'; // 전라북도
      } else if (adminAreaSafe.contains('광주') || adminAreaSafe.contains('전남') || adminAreaSafe.contains('전라남도')) {
        return '11F20000'; // 광주/전라남도
      } else if (adminAreaSafe.contains('대구') || adminAreaSafe.contains('경북') || adminAreaSafe.contains('경상북도')) {
        return '11H10000'; // 대구/경상북도
      } else if (adminAreaSafe.contains('부산') || adminAreaSafe.contains('울산') || adminAreaSafe.contains('경남') || adminAreaSafe.contains('경상남도')) {
        return '11H20000'; // 부산/울산/경상남도
      } else if (adminAreaSafe.contains('제주')) {
        return '11G00000'; // 제주도
      }
        print("Failed to map administrative area: $adminAreaSafe. Falling back to Seoul code.");
        return seoulRegId;
    } catch (e) {
      // placemarks[0] 접근 자체가 실패하는 등 예외적인 경우
      print("Geocoding Data Extraction Error (Secondary Catch): $e. Falling back to Seoul code.");
      return seoulRegId;
    }
  }

  // 단기예보 SKY(하늘 상태) 코드표
  static const Map<int, String> SKY_MAP = {
    1: '맑음',      // 전운량 0~5
    3: '구름 많음', // 전운량 6~8
    4: '흐림',      // 전운량 9~10
  };

  // 단기예보 PTY(강수 형태) 코드표
  static const Map<int, String> PTY_MAP = {
    0: '없음',
    1: '비',
    2: '비/눈',
    3: '눈',
    4: '소나기',
    5: '빗방울',
    6: '빗방울/눈날림',
    7: '눈날림',
  };

  // 중기예보 날씨 문자열 표준화 맵 (wf4, wf7 등)
  static const Map<String, String> MID_TERM_WEATHER_MAP = {
    '맑음': '맑음',
    '구름많음': '구름 많음',
    '구름 많음': '구름 많음',
    '흐림': '흐림',
    '비': '비',
    '비/눈': '비/눈',
    '눈': '눈',
    '소나기': '소나기',
  };

  String _getShortTermWeatherDescription(int skyCode, int ptyCode) {
    if (ptyCode != 0) {
      // PTY != 0 => (비, 눈 등), PTY 설명 우선
      return PTY_MAP[ptyCode] ?? '강수(불명)';
    }

    // PTY == 0 => (강수 없음), SKY 코드 사용
    return SKY_MAP[skyCode] ?? '날씨(불명)';
  }

  // --- 단기예보 필수: Base Time 결정 ---
  // --- 단기예보 필수: Base Date/Time 결정 ---
  Map<String, String> _getShortTermBaseDateTime() {
    final now = DateTime.now();
    DateTime baseDateTime = now; // 초기값은 현재 시각
    int baseHour = 0;

    // API 제공 시간(~이후)은 발표 시각 + 10분
    const int delayMinutes = 10;

    // 발표 시각 (3시간 간격)
    final baseTimes = [23, 20, 17, 14, 11, 8, 5, 2];

    for (var time in baseTimes) {
      // 발표 시각 (BaseTime)과 데이터 사용 가능 시각 (BaseTime + 10분)
      final availableTime = DateTime(now.year, now.month, now.day, time, delayMinutes);

      // 현재 시간이 데이터 사용 가능 시각보다 같거나 이후라면
      if (now.isAfter(availableTime) || now.isAtSameMomentAs(availableTime)) {
        baseHour = time;
        baseDateTime = availableTime.subtract(Duration(minutes: delayMinutes)); // 발표 시각으로 설정
        break;
      }
    }

    // 모든 시각을 역순으로 검토했는데도 BaseHour가 0이면, 전날 23시 데이터 사용
    if (baseHour == 0) {
      baseHour = 23;
      // 전날 23시 데이터는 현재 시각이 00:00 ~ 02:10 사이에 요청됨.
      // 따라서 Base Date는 전날이 되어야 함.
      baseDateTime = now.subtract(const Duration(days: 1));
    }

    final baseDateStr = '${baseDateTime.year}${baseDateTime.month.toString().padLeft(2, '0')}${baseDateTime.day.toString().padLeft(2, '0')}';
    final baseTimeStr = baseHour.toString().padLeft(2, '0') + '00';

    return {
      'baseDate': baseDateStr,
      'baseTime': baseTimeStr,
    };
  }

  // --- 중기예보 필수: Base Date/Time 결정 ---
  // 중기예보는 하루 두 번 (06시, 18시) 발표
  String _getMidTermBaseTime() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // 현재 시간이 18:00 이후면 1800, 06:00 이후면 0600
    String time = '0600';
    if (now.hour >= 18) {
      time = '1800';
    } else if (now.hour < 6) {
      // 00:00~06:00 사이는 전날 1800 데이터 사용
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayDate = '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';
      return yesterdayDate + '1800';
    }

    return date + time;
  }

  // 단기예보 (0~3일) 데이터 호출
  Future<List<dynamic>> fetchShortTermForecast(Position position) async {
    final coords = KmaCoordinateConverter.convert(position.latitude, position.longitude);
    final nx = coords['nx'];
    final ny = coords['ny'];

    //final nx = 88; // 진주 근처의 유효한 값
    //final ny = 91; // 진주 근처의 유효한 값

    final baseDateTime = _getShortTermBaseDateTime();
    final baseDate = baseDateTime['baseDate'];
    final baseTime = baseDateTime['baseTime'];

    final url = Uri.parse(
        '$shortTermEndpoint?'
            'serviceKey=$weatherApiKey'
            '&numOfRows=300'
            '&pageNo=1'
            '&dataType=JSON' // JSON으로 요청하도록 명시
            '&base_date=$baseDate'
            '&base_time=$baseTime'
            '&nx=$nx'
            '&ny=$ny'
    );

    print('ShortTerm URL: $url'); // 요청 URL 출력

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));

      final resultCode = json?['response']?['header']?['resultCode'];
      final resultMsg = json?['response']?['header']?['resultMsg'];
      if (resultCode != '00') {
        print('ShortTerm API Response Error: Code $resultCode, Msg: $resultMsg');
        // resultCode가 03 (NO_DATA)인 경우 빈 리스트 반환하여 앱 충돌 방지
        if (resultCode == '03') return [];
        // 10 (파라미터 오류)와 같은 치명적 오류는 예외 발생
        throw Exception('단기예보 API 오류: $resultMsg (Code $resultCode)');
      }

      print('ShortTerm API Success (200). Data length: ${response.bodyBytes.length} bytes.');

      return json?['response']?['body']?['items']?['item'] ?? [];
    } else {
      // ⭐️ 디버깅 로그 추가: 실패 시 상태 코드 및 응답 본문 출력
      print('ShortTerm API Failed (Status: ${response.statusCode}). Response Body: ${utf8.decode(response.bodyBytes)}');
      throw Exception('단기예보 호출 실패: ${response.statusCode}');
    }
  }

  // 중기예보 (3~10일) 데이터 호출
  Future<Map<String, dynamic>?> fetchMidTermForecast(Position position) async {
    final regId = await _getRegId(position.latitude, position.longitude);
    final tmFc = _getMidTermBaseTime();

    final url = Uri.parse('$midTermEndpoint?'
        'serviceKey=$weatherApiKey'
        '&numOfRows=10'
        '&pageNo=1'
        '&dataType=JSON' // JSON으로 요청하도록 명시
        '&regId=$regId'
        '&tmFc=$tmFc');

    print('MidTerm URL: $url'); // 요청 URL 출력

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));

      final resultCode = json?['response']?['header']?['resultCode'];
      final resultMsg = json?['response']?['header']?['resultMsg'];
      if (resultCode != '00') {
        print('MidTerm API Response Error: Code $resultCode, Msg: $resultMsg');
        return null; // 중기 예보는 데이터가 없으면 null 반환
      }

      print('MidTerm API Success (200). Data length: ${response.bodyBytes.length} bytes.');

      final items = json?['response']?['body']?['items']?['item'] ?? [];
      return items.isNotEmpty ? items[0] : null;
    } else {

      print('MidTerm API Failed (Status: ${response.statusCode}). Response Body: ${utf8.decode(response.bodyBytes)}');
      throw Exception('중기예보 호출 실패: ${response.statusCode}');
    }
  }

  // 단기/중기 데이터 통합 호출
  Future<List<WeatherDay>> fetchAllWeatherForecast(Position position) async {
    // 병렬 처리
    final shortTermFuture = fetchShortTermForecast(position);
    final midTermFuture = fetchMidTermForecast(position);

    final List<dynamic> shortTermData = await shortTermFuture;
    final Map<String, dynamic>? midTermData = await midTermFuture;

    // 단기 예보 데이터 파싱 및 3일치 데이터 준비
    final Map<DateTime, List<dynamic>> parsedShortTerm = _parseShortTermData(shortTermData);
    final List<WeatherDay> dailyForecasts = _getInitialDailyForecasts(parsedShortTerm);

    // 중기 예보 데이터 파싱 및 4~7일치 데이터 추가
    if (midTermData != null) {
      _addMidTermData(dailyForecasts, midTermData);
    }

    return dailyForecasts;
  }

  Map<DateTime, List<dynamic>> _parseShortTermData(List<dynamic> items) {
    final Map<DateTime, List<dynamic>> groupedData = {};

    const List<String> requiredCategories = ['SKY', 'PTY', 'TMP', 'TMN', 'TMX', 'POP', 'RN1'];

    for (var item in items) {
      final dateStr = item['fcstDate'] as String;
      final category = item['category'] as String;

      if (requiredCategories.contains(category)) {
        final targetDate = DateTime.parse(dateStr);
        // 시간 정보를 제거하고 날짜만 키로 사용
        final dateKey = DateTime(targetDate.year, targetDate.month, targetDate.day);

        if (!groupedData.containsKey(dateKey)) {
          groupedData[dateKey] = [];
        }
        groupedData[dateKey]!.add(item);
      }
    }
    return groupedData;
  }

  // 단기 예보 기반 초기 WeatherDay 리스트 생성 (0~3일치)
  List<WeatherDay> _getInitialDailyForecasts(Map<DateTime, List<dynamic>> parsedData) {
    final List<WeatherDay> forecasts = [];
    final now = DateTime.now();

    // 현재 +3일까지 데이터 처리 (총 4일치: 0일차, 1일차, 2일차, 3일차)
    for (int i = 0; i < 4; i++) {
      final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: i));

      if (parsedData.containsKey(targetDate)) {
        final dayItems = parsedData[targetDate]!;

        int maxPty = 0;
        int representativeSky = 1;
        int representativeHour = 0;

        double? minTemp;
        double? maxTemp;
        double? currentTemp;
        int maxRainProb = 0; // 강수 확률의 최댓값
        double? maxRainAmount; // 강수량의 최댓값

        for (var item in dayItems) {
          final category = item['category'];
          final valueStr = item['fcstValue'].toString();
          final valueInt = int.tryParse(valueStr) ?? 0;
          final valueDouble = double.tryParse(valueStr);
          final fcstTimeStr = item['fcstTime'] as String;

          switch (category) {
            case 'PTY': // 강수 형태
              if (valueInt > maxPty) maxPty = valueInt;
              break;
            case 'SKY': // 하늘 상태 (PTY가 없을 때만 중요)
              if (valueInt > representativeSky) representativeSky = valueInt;
              if (fcstTimeStr.length >= 2) {
                representativeHour = int.parse(fcstTimeStr.substring(0, 2));
              }
              break;
            case 'TMN': // 최저 기온 (하루에 한 번만 존재)
              if (valueDouble != null) minTemp = valueDouble;
              break;
            case 'TMX': // 최고 기온 (하루에 한 번만 존재)
              if (valueDouble != null) maxTemp = valueDouble;
              break;
            case 'TMP': // 3시간 간격 기온 (오늘 날짜의 현재 기온으로 사용)
            // 오늘(i=0)이고 현재 시간(10:10 PM KST)에 가장 가까운 TMP를 currentTemp로 저장
              if (i == 0 && valueDouble != null) {
                currentTemp = valueDouble;
              }
              break;
            case 'POP': // 강수 확률 (최댓값 저장)
              if (valueInt > maxRainProb) maxRainProb = valueInt;
              break;
            case 'RN1': // 1시간 강수량 (최댓값 저장)
              if (valueDouble != null && (maxRainAmount == null || valueDouble > maxRainAmount!)) {
                maxRainAmount = valueDouble;
              }
              break;
          }
        }

        // --- WeatherDay 객체 생성 ---
        if (dayItems.isNotEmpty) {
          final description = _getShortTermWeatherDescription(representativeSky, maxPty);

          int pcp = 0;
          int sno = 0;

          if (maxPty == 1 || maxPty == 4 || maxPty == 5) { pcp = 1; }
          else if (maxPty == 3 || maxPty == 7) { sno = 1; }
          else if (maxPty == 2 || maxPty == 6) { pcp = 1; sno = 1; }

          forecasts.add(WeatherDay(
            date: targetDate,
            description: description,
            iconCode: _getIconFileName(representativeSky, maxPty, representativeHour),
            sky: representativeSky,
            pcp: pcp,
            sno: sno,
            currentTemp: currentTemp,
            minTemp: minTemp,
            maxTemp: maxTemp,
            rainProb: maxRainProb,
            rainAmount: maxRainAmount,
          ));
        }
      }
    }
    return forecasts;
  }

  // 4일차 이후 중기데이터 추가
  void _addMidTermData(List<WeatherDay> dailyForecasts, Map<String, dynamic> midTerm) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (int d = 4; d <= 7; d++) {
      final targetDate = today.add(Duration(days: d));

      final String weatherAm = midTerm['wf${d}Am'] ?? midTerm['wf$d'] ?? '흐림'; // 오전 날씨
      final String weatherPm = midTerm['wf${d}Pm'] ?? midTerm['wf$d'] ?? '흐림'; // 오후 날씨

      final String combinedWeather = '$weatherAm $weatherPm'; // 추정용 통합 문자열

      int midSky = 4; // 기본: 흐림 (4)
      int midPcp = 0;
      int midSno = 0;

      if (combinedWeather.contains('비') || combinedWeather.contains('소나기')) {
        midPcp = 1;
        midSky = 3;
      }
      if (combinedWeather.contains('눈')) {
        midSno = 1;
        midSky = 3;
      }
      if (combinedWeather.contains('맑음')) {
        midSky = 1;
      } else if (combinedWeather.contains('구름')) {
        midSky = 3;
      }

      dailyForecasts.add(WeatherDay(
        date: targetDate,
        description: '$weatherAm / $weatherPm', // 오전/오후 날씨 통합 표시
        iconCode: _getMidTermIconCode(weatherAm, weatherPm),
        sky: midSky,
        pcp: midPcp,
        sno: midSno,
      ));
    }
  }

  // 단기예보 아이콘 결정 함수
  String _getIconFileName(int skyCode, int ptyCode, int hour) {
    bool isDay = hour >= 6 && hour < 18;
    String dn = isDay ? 'd' : 'n';

    switch (ptyCode) {
      case 1: // 비
      case 4: // 소나기
      case 5: // 빗방울
        return '10$dn';
      case 2: // 비/눈
      case 3: // 눈
      case 6:
      case 7:
        return '13$dn';
    }

    switch (skyCode) {
      case 1: // 맑음
        return '01$dn';
      case 3: // 구름많음
        return '03$dn';
      case 4: // 흐림
        return '04$dn';
      default:
        return 'default';
    }
  }

  // 중기예보 아이콘 결정 함수
  String _getMidTermIconCode(String am, String pm) {
    // 현재 시간 기준 낮/밤 결정
    bool isDay = DateTime.now().hour >= 6 && DateTime.now().hour < 18;
    String dn = isDay ? 'd' : 'n';

    final text = '$am $pm';

    if (text.contains('비') || text.contains('소나기')) {
      return '10$dn';
    }
    if (text.contains('눈')) {
      return '13$dn';
    }
    if (text.contains('흐림') || text.contains('구름많음')) {
      return '04$dn';
    }
    return '01$dn';
  }
}