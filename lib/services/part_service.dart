
import 'package:flutter/services.dart' show rootBundle;

class PartService {
  Future<Map<String, List<String>>> loadParts() async {
    final String fileContent = await rootBundle.loadString('lib/models/parts.txt');
    final List<String> lines = fileContent.split('\n');

    Map<String, List<String>> categories = {};
    String? currentCategory;
    String? currentBrand;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (['CPU', '그래픽카드', '메인보드'].contains(line)) {
        currentCategory = line;
        categories[currentCategory!] = [];
        currentBrand = null; 
      } else if (currentCategory != null) {
        // Assuming lines that are not categories are either brands or models
        // A simple heuristic: if it's one of the known brands, treat it as such
        if (['AMD', '인텔', 'nVidea'].contains(line)) {
            currentBrand = line;
        } else {
            // Add brand prefix to model name if brand is known
            String modelName = currentBrand != null ? '$currentBrand $line' : line;
            categories[currentCategory]?.add(modelName);
        }
      }
    }
    return categories;
  }
}
