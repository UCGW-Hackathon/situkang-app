class RagParser {
  /// Parses the RAG agent response to extract service names and their baseline prices.
  static Map<String, int> parsePatokanPrices(String ragAnswer) {
    final Map<String, int> prices = {};
    // Strip markdown bolding asterisks
    final cleanAnswer = ragAnswer.replaceAll('**', '').replaceAll('*', '');
    final lines = cleanAnswer.split('\n');
    String? currentService;
    
    for (var line in lines) {
      line = line.trim();
      // Matches lines like: "1. Cat tembok plus bahan Vinilex"
      final headerMatch = RegExp(r'^\d+\.\s*(.+)').firstMatch(line);
      if (headerMatch != null) {
        currentService = headerMatch.group(1)?.trim();
        continue;
      }
      
      if (currentService != null) {
        // Matches "Harga patokan: Rp35.000 per m2" or "Harga patokan: Rp. 85.000" case-insensitively
        final priceMatch = RegExp(
          r'Harga patokan:\s*(?:Rp\.?\s*)?([\d\.,]+)',
          caseSensitive: false,
        ).firstMatch(line);
        
        if (priceMatch != null) {
          final priceRaw = priceMatch.group(1) ?? '0';
          // Clean dot/comma separators to get pure digits
          final priceStr = priceRaw.replaceAll('.', '').replaceAll(',', '');
          final price = int.tryParse(priceStr) ?? 0;
          prices[currentService.toLowerCase()] = price;
          currentService = null;
        }
      }
    }
    return prices;
  }

  /// Finds the baseline price of a given item title by comparing it to parsed baseline prices.
  /// First attempts an exact match, then falls back to a substring match for keys of length >= 4.
  /// If no RAG match is found, falls back to a local catalog of common material prices.
  static int? findPatokanPrice(String itemTitle, Map<String, int> patokanPrices) {
    final cleanTitle = itemTitle.toLowerCase().trim();
    if (cleanTitle.isEmpty) return null;

    // 1. Try exact match first
    if (patokanPrices.containsKey(cleanTitle)) {
      return patokanPrices[cleanTitle];
    }
    
    // 2. Try fuzzy substring match from RAG
    int? bestMatchPrice;
    int bestMatchLength = 0;
    
    for (final entry in patokanPrices.entries) {
      final key = entry.key;
      if (key.length >= 4) {
        if (cleanTitle.contains(key) || key.contains(cleanTitle)) {
          // Prioritize more specific (longer) match
          if (key.length > bestMatchLength) {
            bestMatchLength = key.length;
            bestMatchPrice = entry.value;
          }
        }
      }
    }
    
    if (bestMatchPrice != null) {
      return bestMatchPrice;
    }

    // 3. Fallback: Local catalog of common material prices
    const localMaterialBaselines = {
      'semen instan': 75000,
      'semen gresik': 65000,
      'semen tiga roda': 68000,
      'cat tembok': 50000,
      'cat vinilex': 60000,
      'cat dulux': 120000,
      'stop kontak': 25000,
      'sakelar': 20000,
      'pipa pvc': 35000,
      'kabel nym': 15000,
      'biaya material & bahan': 150000,
      'biaya material': 150000,
      'material & bahan': 150000,
      'material': 150000,
      'instalasi pipa': 150000,
      'pipa': 150000,
    };

    // Normalize strings to alphanumeric only for robust comparison (e.g. "biaya material & bahan" -> "biayamaterialbahan")
    final normalizedTitle = cleanTitle.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalizedTitle.isEmpty) return null;

    for (final entry in localMaterialBaselines.entries) {
      final normalizedKey = entry.key.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalizedTitle.contains(normalizedKey) || normalizedKey.contains(normalizedTitle)) {
        return entry.value;
      }
    }

    return null;
  }
}
