import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';



class ImageAnalyzer{
  static const Map<String, List<String>> levelCategories = {
    '공부': [
      'Chair', 'Desk', 'Blackboard', 'Whiteboard', 'Computer', 'Poster',
      'Presentation', 'School', 'Class', 'Paper', 'Newspaper',
      'Graduation', 'Mortarboard',"Sitting",
    ],
    '운동': [
      'Badminton', 'Bicycle', 'Stadium', 'Surfboard', 'Wetsuit',
      'Windsurfing', 'Sports', 'Cycling', 'Kayak', 'Skateboarder',
      'Skateboard', 'Surfing', 'Rugby', 'Running', 'Gymnastics', 'Rowing',
      'Track', 'Roller', 'Sledding', 'Snowboarding', 'Waterskiing',
      'Skiing', 'Swimming', 'Pool', 'Tubing', 'Muscle', 'Canoe',"Standing",
      'Archery', 'Pitch', 'Soccer', 'Marathon', 'Backpacking', 'Rafting',"Sitting"
    ],
    '식단': [
      "Food","Vegetable", "Fruit", "Meal", "Supper",
      "Lunch", "Cookware and bakeware","Kitchen",
    ],
    '예술': [
      "Musical instrument", "Musical", "Piano",
      "Pop music", "Song", "Musician", "Singer","Drawer",
    ],
    '기타': [
      "Team", "Sunset", "Interaction",
      "Laugh", "Picnic", "Community", "Pillow", "Curtain",
      "Tableware", "Plant", "Flower", "Flowerpot",
      "Camping", "Playground", "Garden", "Forest",
      "Lake", "River", "Mountain", "Waterfall",
      "Roof", "Wall", "Floor", "Window",
      "Hand",
      "Event",
      "Presentation",
      "News"
          "Newspaper",
      "Bus",
      "Car",
      "Bicycle",
      "Road",
      "Building",
      "Museum",
      "Castle",
      "Temple",
      "Church",
      "Farm",
    ]
  };

  //사진 분석
  static Future<String> analyzeCategory(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    // 이미지 라벨러 기능 생성
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    // 이미지 라벨링 수행
    final labels = await imageLabeler.processImage(inputImage);
    imageLabeler.close();

    // 라벨 리스트 저장
    final only_label = labels.map((e) => e.label).toList();

    //초기화
    final categoryCounts = {
      '공부': 0,
      '운동': 0,
      '식단': 0,
      '예술': 0,
      '기타': 0,
    };

    //카테고리별 순수라벨들을 분류하기
    for (var element in only_label) {
      levelCategories.forEach((category, elements) {
        if (elements.contains(element)) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      });
    }

    //분류된 카테고리에서 가장 큰 값 리턴
    return categoryCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}