# ♞ Mobil Satranç Projesi — Stockfish Entegrasyon Mimarisi

## 1. Amaç

Bu doküman, Stockfish motorunun projeye nasıl entegre edileceğini,
hangi modüllerde kullanılacağını ve offline oyun ile analiz süreçlerinde nasıl çalışacağını açıklamak için hazırlanmıştır.

---

## 2. Stockfish Neden Kullanılıyor?

Bu projede Stockfish iki temel amaç için kullanılacaktır:

1. Bilgisayara karşı oyun
2. Oyun analizi

Yani Stockfish sadece "bot" değildir.
Aynı zamanda maç sonrası kalite değerlendirme motorudur.

---

## 3. Kullanım Alanları

## 3.1 Offline Oyun
- kullanıcı hamle yapar
- mevcut pozisyon Stockfish'e verilir
- Stockfish en iyi cevabı üretir
- bot bu hamleyi oynar

## 3.2 Oyun Analizi
- kayıtlı maçın hamleleri yüklenir
- her hamle sonrası pozisyon analiz edilir
- en iyi hamle ile oyuncunun yaptığı hamle karşılaştırılır
- sınıflandırma yapılır

---

## 4. Mimari Yaklaşım

Stockfish entegrasyonu için iki temel yaklaşım vardır:

## Yaklaşım A — Backend üzerinden çalıştırma
- Stockfish backend sunucuda process olarak çalışır
- Flutter istemcisi analiz veya bot hamlesi için backend'e istek gönderir
- backend sonucu döner

### Avantajları
- tek merkezden kontrol
- analiz sonuçları backend'de üretilebilir
- güvenli ve yönetilebilir
- web ve mobil aynı mantığı kullanır

### Dezavantajları
- sunucu yükü artar
- anlık offline deneyimde gecikme olabilir

## Yaklaşım B — İstemci tarafında çalıştırma
- Stockfish mobil cihazda çalıştırılır
- bot hamlesi cihaz içinde üretilir

### Avantajları
- hızlı local deneyim
- sunucu bağımsız

### Dezavantajları
- platform bağımlılığı
- entegrasyon daha zor olabilir
- web ve mobil davranışı ayrışabilir

---

## 5. Bu Proje İçin Önerilen Model

Final projesi için öneri:

## Karma model
- Offline oyun için: mümkünse istemci tarafı ya da hafif backend desteği
- Analiz için: backend tarafında Stockfish

Ama sade tutmak istenirse şu da yapılabilir:
- Hem offline bot hem analiz backend üzerinden çalışsın

Bu ikinci yol daha kolay yönetilir.

---

## 6. Entegrasyon Katmanları

## 6.1 Flutter Katmanı
Görevleri:
- kullanıcı hamlesini almak
- backend'e pozisyon göndermek
- dönen hamleyi tahtaya uygulamak
- analiz ekranında sonuçları göstermek

## 6.2 Backend Katmanı
Görevleri:
- Stockfish process'ini başlatmak
- UCI komutları göndermek
- cevabı parse etmek
- bot hamlesi veya analiz sonucunu istemciye döndürmek

## 6.3 Stockfish Process Katmanı
Görevleri:
- UCI komutları almak
- pozisyon analiz etmek
- bestmove ve evaluation üretmek

---

## 7. UCI Temeli

Stockfish, UCI adlı standart komut setiyle çalışır.

Temel komutlar:
- uci
- isready
- ucinewgame
- position fen ...
- position startpos moves ...
- go depth 10
- go movetime 1000
- bestmove

---

## 8. Offline Oyun Akışı

## 8.1 Senaryo
1. Kullanıcı oyunu başlatır
2. Game state oluşur
3. Kullanıcı hamle yapar
4. Hamle local doğrulanır
5. Pozisyon backend'e gönderilir
6. Backend Stockfish'e sorar
7. Stockfish bestmove döner
8. Backend hamleyi Flutter'a döner
9. Bot hamlesi uygulanır

## 8.2 Örnek İstek
**POST** `/api/engine/best-move`

```json
{
  "fen": "current fen",
  "difficulty": 3,
  "moveTimeMs": 1000
}
```

## 8.3 Örnek Yanıt
```json
{
  "bestMove": "e7e5",
  "san": "e5",
  "evaluation": 0.12
}
```

---

## 9. Analiz Akışı

## 9.1 Senaryo
1. Kullanıcı geçmiş maç seçer
2. Maçın PGN/FEN akışı backend'e gelir
3. Backend her pozisyonu sırayla analiz eder
4. En iyi hamle ve evaluation hesaplanır
5. Oyuncunun hamlesiyle karşılaştırma yapılır
6. Classification üretilir
7. Sonuç AnalysisResults tablosuna yazılır
8. İstemci analiz ekranında gösterir

---

## 10. Sınıflandırma Mantığı

Basit sınıflandırma yaklaşımı:

- Best
- Good
- Inaccuracy
- Mistake
- Blunder

Bu sınıflandırma, oynanan hamlenin değerlendirmesi ile en iyi hamle arasındaki farktan türetilebilir.

Örnek mantık:
- fark çok düşükse → Best
- biraz düşükse → Good
- orta sapma → Inaccuracy
- yüksek sapma → Mistake
- çok büyük sapma → Blunder

Final projesi için bu yaklaşım yeterince etkileyicidir.

---

## 11. Zorluk Seviyesi Planı

Offline bot için zorluk seviyesi birkaç şekilde yönetilebilir:

## Seçenek 1 — Search depth
- Easy → depth 4
- Medium → depth 8
- Hard → depth 12

## Seçenek 2 — Move time
- Easy → 300 ms
- Medium → 800 ms
- Hard → 1500 ms

Final projesi için en pratik yöntem:
- move time + düşük/orta/yüksek preset

---

## 12. Backend Servis Tasarımı

Önerilen servis:
- `IStockfishService`
- `StockfishService`

### Sorumluluklar
- process başlatma
- komut gönderme
- output okuma
- bestmove alma
- evaluation alma
- analiz batch işlemi yürütme

### Örnek arayüz
```csharp
public interface IStockfishService
{
    Task<BestMoveResult> GetBestMoveAsync(string fen, int moveTimeMs);
    Task<AnalysisResult> AnalyzePositionAsync(string fen, int depth);
}
```

---

## 13. Dikkat Edilecek Teknik Noktalar

- process yönetimi doğru yapılmalı
- aynı anda çok fazla analiz isteği sunucuyu zorlayabilir
- timeout mekanizması olmalı
- hatalı UCI yanıtları için log tutulmalı
- pozisyon formatı bozuksa analiz başlamamalı

---

## 14. Flutter Tarafı Servisleri

Flutter tarafında:
- `stockfish_api_service.dart`
- `analysis_service.dart`
- `offline_game_provider.dart`

Bu katmanlar backend ile haberleşir.

---

## 15. Test Senaryoları

- başlangıç pozisyonunda bestmove alma
- farklı zorluk seviyelerinde hamle üretimi
- oyun ortası pozisyon analizi
- hatalı FEN gönderme
- uzun PGN analizi
- analiz sonucunu kaydetme

---

## 16. Teslim İçin En Mantıklı Sınır

Final projesi için şu seviye yeterlidir:
- bilgisayara karşı oynama
- 3 zorluk seviyesi
- maç sonrası analiz
- hamle başına sınıflandırma
- en iyi hamle önerisi

Daha ileri motor ayarları gerekmez.

---

## 17. Sonuç

Bu mimari ile Stockfish entegrasyonu:
- yönetilebilir
- genişletilebilir
- sunumda güçlü görünen
- gerçek bir satranç uygulaması hissi veren

bir yapı haline gelir.
