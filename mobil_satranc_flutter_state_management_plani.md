# 🧠 Mobil Satranç Projesi — Flutter State Management Planı

## 1. Amaç

Bu doküman, Flutter tarafında state management yapısının nasıl kurulacağını,
hangi ekranın hangi state'e ihtiyaç duyduğunu ve veri akışının nasıl yönetileceğini açıklamak için hazırlanmıştır.

---

## 2. Neden State Management Gerekli?

Bu projede state yönetimi kritik çünkü:
- auth durumu tutulacak
- kullanıcı bilgileri taşınacak
- online oyunda canlı game state olacak
- offline oyunda anlık board state değişecek
- analiz ekranında yükleme ve sonuç süreçleri olacak

Yerel `setState` bazı küçük yerlerde yeterli olabilir ama tüm proje için merkezi yapı gerekir.

---

## 3. Önerilen Yaklaşım

Bu proje için önerilen yapı:

- **Riverpod** tercih edilir
- daha sade istenirse Provider da kullanılabilir

Ancak:
- modülerlik
- test edilebilirlik
- async state yönetimi
- temiz dependency yönetimi

nedenleriyle Riverpod daha uygundur.

---

## 4. Temel State Alanları

Projede yönetilecek ana state grupları:

1. Auth State
2. User/Profile State
3. Home Dashboard State
4. Offline Game State
5. Online Matchmaking State
6. Online Game State
7. Match History State
8. Analysis State
9. Settings State

---

## 5. Auth State

## Sorumluluklar
- login durumu
- jwt token
- current user
- logout işlemi
- app startup auth check

## Önerilen Providerlar
- authRepositoryProvider
- authControllerProvider
- currentUserProvider
- authTokenProvider

## Tutulacak Alanlar
- isAuthenticated
- token
- user
- isLoading
- errorMessage

---

## 6. Profile State

## Sorumluluklar
- kullanıcı istatistikleri
- elo puanı
- win/loss/draw bilgileri
- elo history

## Önerilen Providerlar
- profileRepositoryProvider
- profileControllerProvider
- eloHistoryProvider

---

## 7. Offline Game State

Bu en kritik state'lerden biridir.

## Sorumluluklar
- current game
- board fen
- move listesi
- current turn
- selected square
- legal moves
- game result
- loading bot move
- difficulty
- player color

## Önerilen Providerlar
- offlineGameControllerProvider
- offlineBoardStateProvider
- offlineMoveListProvider

## Tutulacak Alanlar
- gameId
- fen
- pgn
- moves
- turn
- status
- result
- isBotThinking
- difficulty
- playerColor

---

## 8. Online Matchmaking State

## Sorumluluklar
- eşleşme kuyruğuna girme
- bekleme süresi
- room code oluşturma
- room code ile katılma
- rakip bulundu bilgisini yönetme

## Önerilen Providerlar
- matchmakingControllerProvider
- matchmakingStatusProvider

## Tutulacak Alanlar
- isSearching
- queuedAt
- roomCode
- matchFound
- foundGameId
- opponentPreview

---

## 9. Online Game State

Bu state çok dikkatli tasarlanmalı.

## Sorumluluklar
- mevcut online maç bilgisi
- board state
- rakip bilgisi
- timer state
- connection state
- move history
- draw offer state
- game result

## Önerilen Providerlar
- onlineGameControllerProvider
- signalrServiceProvider
- connectionStatusProvider

## Tutulacak Alanlar
- gameId
- whitePlayer
- blackPlayer
- fen
- moves
- turn
- result
- isConnected
- isOpponentConnected
- myColor
- timeLeft
- opponentTimeLeft
- hasPendingDrawOffer

---

## 10. Match History State

## Sorumluluklar
- geçmiş maçları çekmek
- filtrelemek
- sayfalama yapmak

## Önerilen Providerlar
- matchHistoryControllerProvider
- matchHistoryFilterProvider

## Tutulacak Alanlar
- items
- page
- pageSize
- totalCount
- selectedFilter
- isLoading
- error

---

## 11. Analysis State

## Sorumluluklar
- analiz başlatma
- analiz sonucu çekme
- hamle seçimi
- seçilen hamlenin detayını gösterme

## Önerilen Providerlar
- analysisControllerProvider
- selectedMoveProvider

## Tutulacak Alanlar
- gameId
- isLoading
- summary
- moveAnalyses
- selectedMoveIndex
- errorMessage

---

## 12. Settings State

## Sorumluluklar
- tema tercihi
- ses ayarı
- bildirim tercihi

## Önerilen Providerlar
- settingsControllerProvider

---

## 13. Katmanlı Veri Akışı

Önerilen veri akışı:

UI → Controller/Notifier → Repository → Service/API → Response → State → UI

Bu yapı sayesinde:
- ekranlar sade kalır
- business logic widget içine gömülmez
- test yazmak kolaylaşır

---

## 14. Önerilen Klasör Düzeni

Örnek feature bazlı state yapısı:

```text
features/
  auth/
    provider/
      auth_controller.dart
      auth_state.dart
  offline_game/
    provider/
      offline_game_controller.dart
      offline_game_state.dart
  online_game/
    provider/
      online_game_controller.dart
      online_game_state.dart
```

---

## 15. State Sınıfı Örneği

```dart
class OfflineGameState {
  final String fen;
  final List<String> moves;
  final bool isBotThinking;
  final String turn;
  final String? result;

  const OfflineGameState({
    required this.fen,
    required this.moves,
    required this.isBotThinking,
    required this.turn,
    this.result,
  });
}
```

---

## 16. Async State Yönetimi

Riverpod tarafında:
- AsyncValue
- StateNotifier
- Notifier / AsyncNotifier

yapıları kullanılabilir.

Öneri:
- network işlemleri için AsyncNotifier
- game flow için StateNotifier benzeri kontrollü yapı

---

## 17. SignalR ile State İlişkisi

Online game state, gelen gerçek zamanlı eventlere göre güncellenir.

Örnek:
- `MoveReceived` → fen + moves güncellenir
- `OpponentDisconnected` → bağlantı state değişir
- `GameEnded` → result güncellenir
- `DrawOffered` → modal state açılır

---

## 18. UI Güncelleme Stratejisi

Her küçük değişiklik tüm ekranı rebuild etmemeli.

Bu yüzden:
- board state ayrı
- timer state ayrı
- move list ayrı
- connection badge ayrı

yapılabilir.

Bu performans açısından daha iyi olur.

---

## 19. Hata Yönetimi

Her controller state içinde:
- loading
- success
- error

durumları açıkça yönetilmeli.

Örnek hata durumları:
- login başarısız
- eşleşme bulunamadı
- move gönderilemedi
- analiz alınamadı

---

## 20. Kalıcı Saklama

Bazı state'ler cihazda tutulabilir:
- jwt token
- tema tercihi
- son kullanıcı bilgisi

Bunun için:
- shared_preferences
veya
- secure storage

kullanılabilir.

---

## 21. Minimum Gerekli Provider Listesi

- authControllerProvider
- currentUserProvider
- profileControllerProvider
- offlineGameControllerProvider
- matchmakingControllerProvider
- onlineGameControllerProvider
- matchHistoryControllerProvider
- analysisControllerProvider
- settingsControllerProvider

---

## 22. Sonuç

Bu state management planı sayesinde:
- Flutter kodu düzenli olur
- ekranlar kontrol edilebilir kalır
- online ve offline oyun akışı karışmaz
- proje büyüdüğünde dağılmaz

Bu yapı, final projesi için yeterince profesyonel ve geliştirilebilir bir temel sunar.
