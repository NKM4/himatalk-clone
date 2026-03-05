/// NGワードフィルタ（APK: ChatUtils.smali NG_WORDS_REGEX準拠）
/// セキュリティ強化: 連絡先交換、不適切コンテンツをブロック
class NgWordFilter {
  static final NgWordFilter _instance = NgWordFilter._internal();
  factory NgWordFilter() => _instance;
  NgWordFilter._internal();

  /// APKから抽出したNGワードパターン（74個）
  static final List<RegExp> _patterns = [
    // LINE関連
    RegExp(r'(?:ら|ラ)(?:い|イ)(?:ん|ン)', caseSensitive: false),
    RegExp(r'line', caseSensitive: false),
    RegExp(r'らいん', caseSensitive: false),
    RegExp(r'ライン', caseSensitive: false),
    RegExp(r'L\s*I\s*N\s*E', caseSensitive: false),
    RegExp(r'l\s*i\s*n\s*e', caseSensitive: false),

    // カカオトーク関連
    RegExp(r'(?:か|カ)(?:か|カ)(?:お|オ)', caseSensitive: false),
    RegExp(r'kakao', caseSensitive: false),
    RegExp(r'カカオ', caseSensitive: false),

    // 電話番号パターン
    RegExp(r'\d{2,4}[-\s]?\d{2,4}[-\s]?\d{3,4}'),
    RegExp(r'(?:０|0)(?:７|7|９|9|８|8)(?:０|0)[-\s]?\d{4}[-\s]?\d{4}'),
    RegExp(r'電話', caseSensitive: false),
    RegExp(r'でんわ', caseSensitive: false),
    RegExp(r'番号', caseSensitive: false),

    // メールアドレス関連
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    RegExp(r'メアド', caseSensitive: false),
    RegExp(r'めあど', caseSensitive: false),
    RegExp(r'アドレス', caseSensitive: false),

    // SNS関連
    RegExp(r'(?:い|イ)(?:ん|ン)(?:す|ス)(?:た|タ)', caseSensitive: false),
    RegExp(r'instagram', caseSensitive: false),
    RegExp(r'twitter', caseSensitive: false),
    RegExp(r'ツイッター', caseSensitive: false),
    RegExp(r'(?:て|テ)(?:れ|レ)(?:ぐ|グ)(?:ら|ラ)(?:む|ム)', caseSensitive: false),
    RegExp(r'telegram', caseSensitive: false),
    RegExp(r'discord', caseSensitive: false),
    RegExp(r'ディスコード', caseSensitive: false),

    // 出会い系・援助交際関連
    RegExp(r'(?:え|エ)(?:ん|ン)(?:こ|コ)(?:う|ウ)', caseSensitive: false),
    RegExp(r'援交', caseSensitive: false),
    RegExp(r'援助', caseSensitive: false),
    RegExp(r'(?:せ|セ)(?:ふ|フ)(?:れ|レ)', caseSensitive: false),
    RegExp(r'セフレ', caseSensitive: false),
    RegExp(r'ワンナイト', caseSensitive: false),
    RegExp(r'(?:わ|ワ)(?:ん|ン)(?:な|ナ)(?:い|イ)', caseSensitive: false),
    RegExp(r'大人の関係', caseSensitive: false),
    RegExp(r'体の関係', caseSensitive: false),
    RegExp(r'パパ活', caseSensitive: false),
    RegExp(r'ママ活', caseSensitive: false),
    RegExp(r'(?:ぱ|パ)(?:ぱ|パ)(?:か|カ)(?:つ|ツ)', caseSensitive: false),

    // 金銭関連
    RegExp(r'お金', caseSensitive: false),
    RegExp(r'(?:お|オ)(?:か|カ)(?:ね|ネ)', caseSensitive: false),
    RegExp(r'円', caseSensitive: false),
    RegExp(r'万円', caseSensitive: false),
    RegExp(r'振込', caseSensitive: false),
    RegExp(r'振り込', caseSensitive: false),
    RegExp(r'銀行', caseSensitive: false),
    RegExp(r'口座', caseSensitive: false),

    // 性的表現
    RegExp(r'(?:え|エ)(?:っ|ッ)?(?:ち|チ)', caseSensitive: false),
    RegExp(r'エッチ', caseSensitive: false),
    RegExp(r'(?:せ|セ)(?:っ|ッ)(?:く|ク)(?:す|ス)', caseSensitive: false),
    RegExp(r'セックス', caseSensitive: false),
    RegExp(r'(?:お|オ)(?:っ|ッ)?(?:ぱ|パ)(?:い|イ)', caseSensitive: false),
    RegExp(r'おっぱい', caseSensitive: false),
    RegExp(r'(?:ち|チ)(?:ん|ン)(?:こ|コ|ぽ|ポ)', caseSensitive: false),
    RegExp(r'(?:ま|マ)(?:ん|ン)(?:こ|コ)', caseSensitive: false),
    RegExp(r'裸', caseSensitive: false),
    RegExp(r'ヌード', caseSensitive: false),
    RegExp(r'全裸', caseSensitive: false),
    RegExp(r'脱い', caseSensitive: false),
    RegExp(r'脱ぐ', caseSensitive: false),

    // 勧誘・詐欺関連
    RegExp(r'稼げ', caseSensitive: false),
    RegExp(r'儲か', caseSensitive: false),
    RegExp(r'投資', caseSensitive: false),
    RegExp(r'ビジネス', caseSensitive: false),
    RegExp(r'副業', caseSensitive: false),
    RegExp(r'マルチ', caseSensitive: false),
    RegExp(r'MLM', caseSensitive: false),
    RegExp(r'勧誘', caseSensitive: false),
    RegExp(r'無料で', caseSensitive: false),
    RegExp(r'クリック', caseSensitive: false),
    RegExp(r'http://', caseSensitive: false),
    RegExp(r'https://', caseSensitive: false),

    // 違法行為
    RegExp(r'薬', caseSensitive: false),
    RegExp(r'クスリ', caseSensitive: false),
    RegExp(r'大麻', caseSensitive: false),
    RegExp(r'覚せい剤', caseSensitive: false),
    RegExp(r'ドラッグ', caseSensitive: false),
  ];

  /// テキストがNGワードを含むかチェック（static）
  static bool containsNgWord(String text) {
    for (final pattern in _patterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// NGワードを検出して返す（static）
  static List<String> detectNgWords(String text) {
    final detected = <String>[];
    for (final pattern in _patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        detected.add(match.group(0) ?? '');
      }
    }
    return detected;
  }

  /// NGワードを伏字に置換（static）
  static String censorNgWords(String text) {
    var result = text;
    for (final pattern in _patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        return '*' * (match.group(0)?.length ?? 1);
      });
    }
    return result;
  }

  /// バリデーション結果（static）
  static NgWordValidationResult validate(String text) {
    final detected = detectNgWords(text);
    if (detected.isEmpty) {
      return NgWordValidationResult(isValid: true, detectedWords: []);
    }
    return NgWordValidationResult(
      isValid: false,
      detectedWords: detected,
      message: '不適切な内容が含まれています',
    );
  }
}

/// NGワードバリデーション結果
class NgWordValidationResult {
  final bool isValid;
  final List<String> detectedWords;
  final String? message;

  NgWordValidationResult({
    required this.isValid,
    required this.detectedWords,
    this.message,
  });

  /// エラーメッセージ（main.dartから参照）
  String? get error => message;
}
