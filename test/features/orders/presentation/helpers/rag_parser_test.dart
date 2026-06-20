import 'package:flutter_test/flutter_test.dart';
import 'package:situkang_app/features/orders/presentation/helpers/rag_parser.dart';

void main() {
  group('RagParser - parsePatokanPrices', () {
    test('should parse standard clean response format successfully', () {
      const response = '''
Layanan fixed price yang paling relevan:
1. Cat tembok plus bahan Vinilex
   Service code: CT-005.
   Harga patokan: Rp35.000 per m2.
2. Tambah stop kontak
   Service code: EL-005.
   Harga patokan: Rp 85.000 per titik.
''';

      final result = RagParser.parsePatokanPrices(response);
      expect(result.length, 2);
      expect(result['cat tembok plus bahan vinilex'], 35000);
      expect(result['tambah stop kontak'], 85000);
    });

    test('should parse markdown bolded response format successfully', () {
      const response = '''
Layanan fixed price yang paling relevan:
1. **Cat tembok plus bahan Vinilex**
   Service code: CT-005.
   Harga patokan: **Rp35.000** per m2.
2. **Tambah stop kontak**
   Service code: EL-005.
   Harga patokan: **Rp 85.000** per titik.
''';

      final result = RagParser.parsePatokanPrices(response);
      expect(result.length, 2);
      expect(result['cat tembok plus bahan vinilex'], 35000);
      expect(result['tambah stop kontak'], 85000);
    });

    test('should parse formats without Rp prefix or with commas successfully', () {
      const response = '''
Layanan:
1. Jasa Pengecatan Tembok
   Harga patokan: 25,000 per m2.
2. Pemasangan Sakelar Baru
   Harga patokan: Rp.120.000
''';

      final result = RagParser.parsePatokanPrices(response);
      expect(result.length, 2);
      expect(result['jasa pengecatan tembok'], 25000);
      expect(result['pemasangan sakelar baru'], 120000);
    });
  });

  group('RagParser - findPatokanPrice', () {
    final Map<String, int> patokanPrices = {
      'cat tembok plus bahan vinilex': 35000,
      'tambah stop kontak': 85000,
      'cat tembok': 20000,
    };

    test('should return null for empty query', () {
      expect(RagParser.findPatokanPrice('', patokanPrices), isNull);
    });

    test('should return exact match ignoring case', () {
      expect(
        RagParser.findPatokanPrice('Tambah Stop Kontak', patokanPrices),
        85000,
      );
    });

    test('should return substring match when title is suffix/prefix', () {
      expect(
        RagParser.findPatokanPrice('Tambah stop kontak di kamar tidur', patokanPrices),
        85000,
      );
    });

    test('should prioritize longer specific matches over shorter ones', () {
      // "Cat tembok plus bahan Vinilex" should match the 35000 baseline, not the 20000 "cat tembok" baseline
      expect(
        RagParser.findPatokanPrice('Pekerjaan Cat tembok plus bahan Vinilex', patokanPrices),
        35000,
      );
    });

    test('should fall back to local catalog of material prices when no RAG match is found', () {
      expect(
        RagParser.findPatokanPrice('Semen Instan 1 sak 40 kg', patokanPrices),
        75000,
      );
      expect(
        RagParser.findPatokanPrice('Biaya Material & Bahan', patokanPrices),
        150000,
      );
      expect(
        RagParser.findPatokanPrice('Biaya Material dan Bahan', patokanPrices),
        150000,
      );
      expect(
        RagParser.findPatokanPrice('Biaya Material    &    Bahan', patokanPrices),
        150000,
      );
      expect(
        RagParser.findPatokanPrice('Beli kabel NYM eceran', patokanPrices),
        15000,
      );
      expect(
        RagParser.findPatokanPrice('Pesanan: Instalasi Pipa Baru', patokanPrices),
        150000,
      );
      expect(
        RagParser.findPatokanPrice('Tidak Ada Di Mana Mana', patokanPrices),
        isNull,
      );
    });
  });
}
