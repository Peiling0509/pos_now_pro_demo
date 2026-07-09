import 'package:get/get.dart';
import 'translation_data.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': _mapByLang('en'),
    'ms_MY': _mapByLang('ms'),
    'zh_CN': _mapByLang('zh'),
  };

  Map<String, String> _mapByLang(String lang) {
    final Map<String, String> result = {};

    TranslationData.data.forEach((key, value) {
      result[key] = value[lang] ?? key;
    });

    return result;
  }
}
