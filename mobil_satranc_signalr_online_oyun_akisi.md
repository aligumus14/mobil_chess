# 🔄 Mobil Satranç Projesi — SignalR Online Oyun Akışı

## 1. Amaç

Bu doküman, online satranç maçlarının gerçek zamanlı olarak nasıl işleyeceğini,
istemci ile backend arasındaki veri akışını ve SignalR tabanlı haberleşme yapısını açıklamak için hazırlanmıştır.

---

## 2. Neden SignalR?

SignalR, .NET tarafında gerçek zamanlı iletişim için uygundur.

Bu projede şu ihtiyaçları karşılar:
- rakip oyuncuya hamleyi anında iletme
- maç odası yönetimi
- bağlantı durumunu izleme
- oyun sonucu bilgisini iki tarafa aynı anda gönderme
- bekleme/eşleşme durumlarını canlı yönetme

---

## 3. Genel Akış

Online maç akışı şu sırayla işler:

1. Kullanıcı online oyna ekranına girer
2. Hızlı eşleşme veya oda oluşturma seçer
3. Backend kullanıcıyı kuyruğa alır
4. Rakip bulunursa maç odası oluşturulur
5. Her iki istemci SignalR room'una bağlanır
6. Oyuncuların hamleleri backend'e gönderilir
7. Backend hamleyi doğrular
8. Hamle rakibe yayınlanır
9. Oyun biterse sonuç işlenir
10. ELO güncellenir ve geçmişe kaydedilir

---

## 4. Bağlantı Mimarisi

## 4.1 Ana Bileşenler
- Flutter Mobile Client
- Flutter Web Test Client
- ASP.NET Core Backend
- SignalR Hub
- Chess Rule Engine
- Database

## 4.2 Hub Sorumlulukları
SignalR Hub aşağıdakilerden sorumludur:
- oyuncu bağlantısını takip etmek
- oyun odasına katılım
- hamle yayını
- teslim olma / beraberlik isteği
- bağlantı kopması yönetimi
- maç başlat / maç bitir olayları

---

## 5. Oyun Modları

## 5.1 Hızlı Eşleşme
- kullanıcı "Hızlı Eşleş" butonuna basar
- backend MatchQueue tablosuna kaydeder
- uygun rakip bulunursa Game oluşturulur
- iki oyuncu aynı room'a atanır

## 5.2 Oda Kodu ile Katılma
- kullanıcı oda oluşturur
- backend bir room code üretir
- diğer oyuncu bu kodla katılır
- dolunca oyun başlatılır

---

## 6. Hub Event Planı

## 6.1 İstemciden Sunucuya Giden Eventler
- JoinMatchmaking
- CancelMatchmaking
- CreatePrivateRoom
- JoinPrivateRoom
- JoinGameRoom
- SendMove
- ResignGame
- OfferDraw
- AcceptDraw
- DeclineDraw
- SendReady
- LeaveGame

## 6.2 Sunucudan İstemciye Giden Eventler
- MatchFound
- RoomCreated
- RoomJoined
- GameStarted
- MoveReceived
- InvalidMove
- OpponentDisconnected
- OpponentReconnected
- GameEnded
- DrawOffered
- DrawAccepted
- DrawDeclined
- WaitingStatusUpdated

---

## 7. Oyun Odası Mantığı

Her online maç için bir game room oluşturulur.

Örnek:
- GameId = 8c7d...
- RoomName = game_8c7d

Odaya sadece:
- beyaz oyuncu
- siyah oyuncu
- gerekirse gözlemci yoksa sistem

bağlanır.

---

## 8. Hamle Akışı

## 8.1 Temel Senaryo
1. Oyuncu tahtada hamle yapar
2. Flutter istemcisi hamleyi local olarak ön doğrulamadan geçirir
3. SendMove event'i ile backend'e yollar
4. Backend oyunun mevcut FEN durumunu alır
5. Chess engine ile hamleyi doğrular
6. Geçerliyse:
   - game state güncellenir
   - move kaydedilir
   - current FEN güncellenir
   - iki oyuncuya yayın yapılır
7. Geçersizse InvalidMove döner

## 8.2 Gönderilecek Hamle Verisi
Örnek payload:
```json
{
  "gameId": "guid",
  "from": "e2",
  "to": "e4",
  "promotion": null
}
```

## 8.3 Dönen Hamle Verisi
```json
{
  "gameId": "guid",
  "moveNumber": 1,
  "playerId": "guid",
  "from": "e2",
  "to": "e4",
  "san": "e4",
  "fenAfterMove": "....",
  "turn": "black"
}
```

---

## 9. Eşleşme Akışı

## 9.1 Matchmaking Algoritması
Basit yaklaşım:
- sıradaki oyuncular elo farkına göre eşleştirilir
- ilk sürümde tolerans dar tutulabilir
- uzun süre bekleyene tolerans artırılabilir

Örnek:
- ilk 15 saniye: ±50 elo
- sonra ±100
- sonra ±200

Final projesi için daha sade bir sürüm de yeterlidir.

---

## 10. Bağlantı Kopması Senaryoları

## 10.1 Oyuncu bağlantısı koparsa
- SignalR disconnect olayı tetiklenir
- game room içindeki diğer oyuncuya bildirim gider
- oyuncu belirli süre içinde dönerse oyun devam eder
- dönmezse teknik mağlubiyet veya iptal politikası uygulanır

## 10.2 Önerilen Basit Politika
- 30 saniye reconnect süresi
- dönmezse oyun karşı tarafa galibiyet olarak yazılır

---

## 11. Oyun Sonu Senaryoları

Oyun aşağıdaki durumlarda bitebilir:
- şah mat
- pat
- oyuncu teslim olur
- beraberlik kabul edilir
- süre biter
- rakip bağlantısı tamamen düşer

Oyun bittiğinde:
- game status = Finished
- result işlenir
- pgn finalize edilir
- elo hesaplanır
- istemcilere GameEnded event'i gönderilir

---

## 12. SignalR Hub Sınıf Taslağı

```csharp
public class GameHub : Hub
{
    public async Task JoinGameRoom(string gameId) { }
    public async Task SendMove(MoveRequest request) { }
    public async Task ResignGame(string gameId) { }
    public async Task OfferDraw(string gameId) { }
    public override async Task OnDisconnectedAsync(Exception? exception) { }
}
```

---

## 13. Servis Katmanı İlişkisi

Hub doğrudan tüm mantığı taşımaz.

Temiz mimari için:
- Hub: event giriş/çıkış
- GameService: oyun akışı
- MatchmakingService: eşleşme
- EloService: puan hesaplama
- ConnectionService: bağlantı takibi

---

## 14. Güvenlik Notları

- kullanıcı SignalR bağlantısında auth token ile gelmeli
- oyuncu sadece kendi maçında hamle yapabilmeli
- sırası olmayan oyuncu hamle gönderememeli
- aynı anda iki hamle çakışması önlenmeli
- backend her hamleyi tekrar doğrulamalı

---

## 15. Flutter Tarafı İhtiyaçları

Flutter tarafında:
- SignalR servis katmanı
- connection state yönetimi
- reconnect mekanizması
- gelen eventleri provider/state management üzerinden ekrana aktarma

---

## 16. Test Senaryoları

- mobil vs web eşleşme testi
- geçerli hamle testi
- geçersiz hamle testi
- bağlantı kopma testi
- teslim olma testi
- beraberlik teklifi testi
- oyun sonucu kaydı testi

---

## 17. Sonuç

Bu yapı sayesinde online maç sistemi:
- gerçek zamanlı
- yönetilebilir
- test edilebilir
- final projesi için yeterince profesyonel

hale gelir.
