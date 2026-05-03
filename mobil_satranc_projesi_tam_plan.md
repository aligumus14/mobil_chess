# Mobil Satranç Uygulaması — Baştan Sona Proje Planı

## 1. Proje Özeti

Bu proje, **Flutter** ile geliştirilecek, hem **mobilde** çalışan hem de **Flutter Web** ile test edilebilen bir satranç uygulamasıdır. Uygulamanın amacı yalnızca klasik bir satranç tahtası göstermek değil; aynı zamanda:

- kullanıcı hesabı yönetimi,
- bilgisayara karşı oynama,
- online eşleşme ve gerçek zamanlı oyun,
- ELO puan sistemi,
- oyun geçmişi,
- oyun analizi,
- sade ve öğretim üyesini etkileyecek seviyede temiz bir UI/UX

içeren bütünlüklü bir final projesi ortaya koymaktır.

Bu proje bir ürün mantığıyla planlanacaktır. Yani sadece "çalışan ekranlar" değil, başlangıçtan teslim sunumuna kadar düzenli bir mimari kurulacaktır.

---

## 2. Projenin Temel Amaçları

### 2.1 Akademik hedef
Mobil programlama dersi final projesi olarak değerlendirilebilecek, teknik olarak güçlü ve sunumda etkileyici bir uygulama geliştirmek.

### 2.2 Teknik hedef
Aynı uygulama içinde şu yetenekleri sunmak:

- **Offline oyun**: kullanıcı bilgisayara karşı oynayabilsin.
- **Online oyun**: kullanıcı başka bir kullanıcıyla gerçek zamanlı oynayabilsin.
- **Analiz**: biten maçlar tekrar açılıp analiz edilebilsin.
- **ELO sistemi**: online maçlara bağlı puan değişimi olsun.
- **Geçmiş**: oynanan oyunlar kayıt altına alınsın.

### 2.3 Sunum hedefi
Hocaya şu mesajı net verebilmek:

> Bu proje yalnızca bir satranç tahtası değil; kullanıcı yönetimi, oyun yönetimi, gerçek zamanlı haberleşme, puan sistemi ve analiz modülü olan küçük ölçekli bir dijital satranç platformudur.

---

## 3. Kapsam Tanımı

Proje baştan planlanırken kapsam net çizilmezse iş gereksiz büyür. Bu yüzden sistem üç seviyeye ayrılmıştır.

### 3.1 Zorunlu kapsam
Bunlar proje tesliminde kesin bulunmalıdır:

- kayıt olma / giriş yapma
- ana sayfa
- satranç tahtası gösterimi
- kurallı satranç oynama
- bilgisayara karşı oyun
- online maç
- oyun sonucu ekranı
- maç geçmişi
- profil ve ELO gösterimi
- temel analiz ekranı
- temiz ve tutarlı tasarım

### 3.2 Güçlü gösteren kapsam
Zaman ve durum uygunsa eklenir:

- hızlı eşleşme
- oda kodu ile eşleşme
- oyun süresi
- analizde hamle sınıflandırma
- değerlendirme puanı
- leaderboard

### 3.3 İlk sürümde dışarıda bırakılacaklar
İlk geliştirme aşamasında projeyi gereksiz büyütmemek için bunlar zorunlu değildir:

- arkadaş listesi
- sohbet sistemi
- turnuva sistemi
- push notification
- çok detaylı analiz grafikleri
- bulmaca modu
- tema mağazası / skin sistemi

---

## 4. Seçilen Teknolojiler

### 4.1 Mobil ve web istemci
- **Flutter**
- **Dart**
- **Flutter Web** (ikinci cihaz yerine test istemcisi olarak)

### 4.2 Backend
- **.NET 8 / ASP.NET Core Web API**
- **SignalR** (gerçek zamanlı oyun haberleşmesi)

### 4.3 Veritabanı
Tercih sırası:
- **PostgreSQL**
- veya **SQL Server**

Bu proje için her ikisi de uygundur. Eğer hedef daha taşınabilir ve modern bir yapıysa PostgreSQL önerilir.

### 4.4 ORM ve veri erişimi
- **Entity Framework Core**

### 4.5 Kimlik doğrulama
- **JWT Authentication**

### 4.6 Satranç kural motoru ve UI
- Flutter tarafında **hazır chess kütüphanesi** ile hamle doğrulama ve oyun durumu yönetimi
- **hazır chess board widget** ile tahta gösterimi

### 4.7 Bilgisayara karşı oyun ve analiz
- **Stockfish** satranç motoru

### 4.8 Veri formatları
- **FEN**: pozisyon tutma
- **PGN**: oyun kaydı
- **SAN**: hamle gösterimi

---

## 5. Neden Bu Mimari Seçildi?

### 5.1 Neden Flutter?
- Tek kod tabanıyla mobil + web test imkanı sağlar.
- UI tarafında modern ve temiz ekranlar kolay çıkar.
- Final projesi için hızlı ama güçlü sonuç verir.

### 5.2 Neden .NET?
- SignalR ile gerçek zamanlı yapı güçlüdür.
- Katmanlı mimari kurmak rahattır.
- API, auth, oyun yönetimi ve veri erişimi düzenli inşa edilebilir.

### 5.3 Neden hazır satranç kütüphanesi?
Sıfırdan şah, mat, rok, en passant, terfi gibi tüm kuralları yazmak ciddi zaman alır ve hata riskini artırır. Final projesinde zamanın büyük kısmı mimari, UI ve entegrasyona ayrılmalıdır.

### 5.4 Neden Stockfish?
- Bilgisayara karşı oyun sunar.
- Oyun analizi için güçlü temel oluşturur.
- Projeyi teknik olarak üst seviyeye taşır.

---

## 6. Ürün Vizyonu

Bu uygulama şunu yapmalıdır:

> Kullanıcı uygulamaya giriş yapar, ister bilgisayara karşı ister online başka bir oyuncuya karşı satranç oynar, maçları kaydedilir, puanı değişir, daha sonra bu maçları analiz eder.

Bu vizyona göre uygulama üç temel deneyim üzerine kurulacaktır:

1. **Play vs Computer**
2. **Play Online**
3. **Review & Analyze**

---

## 7. Kullanıcı Türleri

### 7.1 Normal kullanıcı
Sistemde temel olarak tek kullanıcı türü yeterlidir.

Yapabilecekleri:
- kayıt olmak
- giriş yapmak
- profilini görüntülemek
- bilgisayara karşı maç yapmak
- online maç yapmak
- geçmiş oyunlarını görmek
- maç analizi yapmak

### 7.2 Admin
Bu proje için zorunlu değildir. Gerekirse teorik olarak eklenebilir ama ilk sürümde plan dışındadır.

---

## 8. Ana Modüller

### 8.1 Kimlik doğrulama modülü
İşlevler:
- kullanıcı kayıt
- kullanıcı giriş
- token üretimi
- oturum yönetimi
- kullanıcı bilgisi çekme

### 8.2 Profil modülü
İşlevler:
- kullanıcı adı
- mail
- ELO puanı
- toplam galibiyet / mağlubiyet / beraberlik
- son maçlar

### 8.3 Offline oyun modülü
İşlevler:
- kullanıcı vs bilgisayar
- satranç tahtası
- hamle doğrulama
- motor hamlesi üretme
- oyun bitişini tespit etme

### 8.4 Online oyun modülü
İşlevler:
- hızlı eşleşme veya oda katılımı
- oyun odası oluşturma
- hamleleri karşı tarafa aktarma
- sıra kontrolü
- oyun sonucu belirleme
- bağlantı kopması yönetimi

### 8.5 ELO modülü
İşlevler:
- sonuç sonrası puan hesaplama
- yeni ELO’yu kaydetme
- ELO geçmişi saklama

### 8.6 Oyun geçmişi modülü
İşlevler:
- oynanan maçları listeleme
- maç detayını açma
- PGN/FEN verilerini görüntüleme

### 8.7 Analiz modülü
İşlevler:
- bir oyunu seçme
- Stockfish ile değerlendirme
- en iyi hamleyi gösterme
- yapılan hamleyi sınıflandırma

---

## 9. Kullanıcı Akışları

### 9.1 İlk açılış akışı
1. Splash ekranı
2. Giriş / kayıt kararı
3. Login/Register
4. Ana sayfa

### 9.2 Bilgisayara karşı oyun akışı
1. Ana sayfada "Bilgisayara Karşı Oyna"
2. Oyun ayarları seçimi
3. Tahta ekranı açılır
4. Kullanıcı hamle yapar
5. Sistem legal move kontrolü yapar
6. Stockfish hamle üretir
7. Oyun devam eder
8. Sonuç ekranı gösterilir
9. İstenirse analiz ekranına geçilir

### 9.3 Online oyun akışı
1. Ana sayfada "Online Oyna"
2. Hızlı eşleşme veya oda girişi
3. Backend eşleştirme yapar
4. Oyun odası kurulur
5. İki istemci SignalR ile bağlanır
6. Oyuncular sırayla hamle yapar
7. Oyun biter
8. ELO güncellenir
9. Oyun geçmişe kaydedilir

### 9.4 Geçmiş ve analiz akışı
1. Kullanıcı geçmiş ekranına gider
2. Oynanan bir maçı seçer
3. Maç detay ekranı açılır
4. "Analiz Et" seçilir
5. Stockfish değerlendirme üretir
6. Hamle bazlı yorum gösterilir

---

## 10. Sayfa Yapıları

### 10.1 Splash Screen
Amaç: uygulama markası ve yönlendirme.

İçerik:
- uygulama logosu
- kısa slogan
- loading / yönlendirme

### 10.2 Login Screen
İçerik:
- email / kullanıcı adı
- şifre
- giriş butonu
- kayıt ol bağlantısı

### 10.3 Register Screen
İçerik:
- kullanıcı adı
- email
- şifre
- şifre tekrar
- kayıt butonu

### 10.4 Home Screen
İçerik:
- hoş geldin alanı
- mevcut ELO özeti
- ana aksiyon kartları:
  - Bilgisayara Karşı Oyna
  - Online Oyna
  - Oyun Geçmişi
  - Analiz
  - Profil

### 10.5 Profile Screen
İçerik:
- kullanıcı bilgileri
- ELO puanı
- galibiyet / mağlubiyet / beraberlik
- son maçlar listesi

### 10.6 Offline Game Screen
İçerik:
- satranç tahtası
- oyuncu bilgileri
- motor seviyesi
- hamle listesi
- geri al / yeni oyun / vazgeç seçenekleri
- oyun sonu popup

### 10.7 Online Matchmaking Screen
İçerik:
- hızlı eşleşme butonu
- oda oluştur
- oda koduyla katıl
- bekleme alanı
- iptal butonu

### 10.8 Online Game Screen
İçerik:
- satranç tahtası
- beyaz / siyah oyuncu kartları
- süre göstergesi (opsiyonel ilk sürümde)
- hamle listesi
- terk et / beraberlik teklif et (opsiyonel)

### 10.9 Match History Screen
İçerik:
- geçmiş maç listesi
- rakip adı
- sonuç
- tarih
- maç türü
- analiz et butonu

### 10.10 Game Detail Screen
İçerik:
- oyun özeti
- oyuncular
- sonuç
- hamle listesi
- PGN gösterimi
- analize geçiş

### 10.11 Analysis Screen
İçerik:
- tahta
- hamle listesi
- motor önerisi
- değerlendirme etiketi
- önceki / sonraki hamle gezinmesi

### 10.12 Settings Screen (opsiyonel)
İçerik:
- çıkış yap
- tema bilgisi
- uygulama bilgileri

---

## 11. UI/UX Tasarım İlkeleri

### 11.1 Tasarım karakteri
- sade
- profesyonel
- anlaşılır
- fazla renk kullanmayan
- kart tabanlı
- minimal ama boş hissettirmeyen

### 11.2 Görsel dil
- açık arka plan + koyu metin
- tek vurgu rengi
- net call-to-action butonları
- yeterli boşluk
- satranç tahtasını öne çıkaran yapı

### 11.3 Hoca açısından önemli unsurlar
- ilk ekran karmaşık olmamalı
- butonlar net olmalı
- oyun ekranı profesyonel görünmeli
- renk ve tipografi tutarlı olmalı

### 11.4 Kullanılacak tasarım prensipleri
- bilgi gruplama
- görsel hiyerarşi
- net gezinme
- hataya karşı kullanıcıyı koruma
- sade onboarding

### 11.5 UX kararları
- ana ekranda en fazla 5 temel aksiyon
- online ve offline akışların net ayrılması
- maç sonu özet ekranı bulunması
- geçmişten analize geçişin kolay olması

---

## 12. Teknik Mimari

### 12.1 Yüksek seviye mimari
Sistem şu bileşenlerden oluşur:

1. **Flutter Mobile Client**
2. **Flutter Web Test Client**
3. **ASP.NET Core API**
4. **SignalR Hub**
5. **Database**
6. **Stockfish Service**

### 12.2 Temel veri akışları

#### 12.2.1 Auth veri akışı
Flutter → API → kullanıcı doğrulama → JWT → Flutter local storage

#### 12.2.2 Online oyun veri akışı
Flutter → SignalR Hub → backend game service → rakip istemci

#### 12.2.3 Oyun kaydı veri akışı
Oyun bitişi → backend result service → database → history endpoint

#### 12.2.4 Analiz veri akışı
History seçimi → backend analysis endpoint → Stockfish → sonuç dönüşü

---

## 13. Katmanlı Backend Mimarisi

### 13.1 Önerilen yapı
- **API**
- **Application**
- **Domain**
- **Infrastructure**

### 13.2 API katmanı
İçerik:
- Controllers
- SignalR Hubs
- request/response DTO bağlama
- auth middleware entegrasyonu

### 13.3 Application katmanı
İçerik:
- servisler
- use-case mantığı
- iş akışları
- DTO’lar
- validator’lar

### 13.4 Domain katmanı
İçerik:
- entity’ler
- enum’lar
- domain kuralları
- temel iş modelleri

### 13.5 Infrastructure katmanı
İçerik:
- DbContext
- EF Core repository implementasyonları
- JWT servisleri
- Stockfish process çalıştırma servisi
- SignalR destek servisleri

---

## 14. Flutter Uygulama Mimarisi

### 14.1 Yapısal yaklaşım
Feature-based folder structure kullanılacaktır.

### 14.2 Temel bölümler
- core
- config
- services
- models
- features
- shared
- routes

### 14.3 State management
Riverpod önerilir. Sebebi:
- test edilebilirlik
- feature bazlı ayrışma
- okunabilirlik
- uzun vadede daha düzenli yapı

Provider da kullanılabilir; ancak proje büyüyeceği için Riverpod daha güçlü seçimdir.

### 14.4 Navigation
- GoRouter tercih edilir
- auth guard desteği ile korumalı sayfalar yapılır

---

## 15. Proje Dosya Yapısı

### 15.1 Genel depo yapısı
```text
chess-project/
│
├── client/
│   ├── flutter_app/
│   └── flutter_web_test/
│
├── server/
│   ├── Chess.Api/
│   ├── Chess.Application/
│   ├── Chess.Domain/
│   └── Chess.Infrastructure/
│
├── docs/
│   ├── architecture/
│   ├── api/
│   ├── database/
│   └── ui/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── chess_pieces/
│
└── README.md
```

### 15.2 Flutter dosya yapısı
```text
lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── error/
│   └── storage/
│
├── config/
│   ├── env/
│   └── network/
│
├── routes/
│   └── app_router.dart
│
├── shared/
│   ├── widgets/
│   ├── dialogs/
│   └── components/
│
├── models/
│   ├── user_model.dart
│   ├── game_model.dart
│   ├── move_model.dart
│   ├── elo_history_model.dart
│   └── analysis_model.dart
│
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── game_service.dart
│   ├── match_service.dart
│   ├── signalr_service.dart
│   └── stockfish_service.dart
│
├── features/
│   ├── splash/
│   │   └── view/
│   │
│   ├── auth/
│   │   ├── view/
│   │   ├── provider/
│   │   └── widgets/
│   │
│   ├── home/
│   │   ├── view/
│   │   └── widgets/
│   │
│   ├── profile/
│   │   ├── view/
│   │   ├── provider/
│   │   └── widgets/
│   │
│   ├── offline_game/
│   │   ├── view/
│   │   ├── provider/
│   │   ├── widgets/
│   │   └── logic/
│   │
│   ├── online_match/
│   │   ├── view/
│   │   ├── provider/
│   │   └── widgets/
│   │
│   ├── online_game/
│   │   ├── view/
│   │   ├── provider/
│   │   ├── widgets/
│   │   └── logic/
│   │
│   ├── match_history/
│   │   ├── view/
│   │   ├── provider/
│   │   └── widgets/
│   │
│   ├── game_detail/
│   │   ├── view/
│   │   └── widgets/
│   │
│   └── analysis/
│       ├── view/
│       ├── provider/
│       └── widgets/
│
└── main.dart
```

### 15.3 .NET backend dosya yapısı
```text
server/
│
├── Chess.Api/
│   ├── Controllers/
│   ├── Hubs/
│   ├── Middleware/
│   ├── Extensions/
│   ├── Filters/
│   ├── Program.cs
│   └── appsettings.json
│
├── Chess.Application/
│   ├── DTOs/
│   │   ├── Auth/
│   │   ├── Game/
│   │   ├── Match/
│   │   ├── Profile/
│   │   └── Analysis/
│   ├── Interfaces/
│   ├── Services/
│   ├── Validators/
│   └── Mappings/
│
├── Chess.Domain/
│   ├── Entities/
│   ├── Enums/
│   ├── ValueObjects/
│   └── Common/
│
└── Chess.Infrastructure/
    ├── Persistence/
    │   ├── Configurations/
    │   ├── Repositories/
    │   ├── Migrations/
    │   └── ChessDbContext.cs
    ├── Authentication/
    ├── Realtime/
    ├── Stockfish/
    └── Services/
```

---

## 16. Veri Tabanı Tasarımı

### 16.1 Users tablosu
Amaç: sistem kullanıcıları.

Alanlar:
- `Id` : Guid / int
- `Username` : string
- `Email` : string
- `PasswordHash` : string
- `Elo` : int
- `Wins` : int
- `Losses` : int
- `Draws` : int
- `CreatedAt` : datetime
- `UpdatedAt` : datetime
- `IsActive` : bool

### 16.2 Games tablosu
Amaç: tüm maçların ana kaydı.

Alanlar:
- `Id`
- `WhitePlayerId`
- `BlackPlayerId`
- `GameMode` (offline, online)
- `GameType` (rated, casual, vs_computer)
- `Status` (waiting, active, finished, aborted)
- `Result` (white_win, black_win, draw)
- `WinnerUserId`
- `StartFen`
- `CurrentFen`
- `Pgn`
- `StartedAt`
- `EndedAt`

### 16.3 GameMoves tablosu
Amaç: hamle geçmişi.

Alanlar:
- `Id`
- `GameId`
- `MoveNumber`
- `PlayerId`
- `FromSquare`
- `ToSquare`
- `PromotionPiece`
- `San`
- `FenAfterMove`
- `PlayedAt`

### 16.4 EloHistory tablosu
Amaç: ELO değişimlerinin geçmişi.

Alanlar:
- `Id`
- `UserId`
- `GameId`
- `OldElo`
- `NewElo`
- `ChangeAmount`
- `CreatedAt`

### 16.5 MatchQueue tablosu
Amaç: eşleşme kuyruğu.

Alanlar:
- `Id`
- `UserId`
- `EloSnapshot`
- `QueueType`
- `QueuedAt`
- `Status`

### 16.6 AnalysisResults tablosu
Amaç: analiz verileri saklamak istenirse kullanılır.

Alanlar:
- `Id`
- `GameId`
- `MoveNumber`
- `BestMove`
- `PlayedMove`
- `Evaluation`
- `Classification`
- `CreatedAt`

---

## 17. Veri Tipleri ve Domain Modelleri

### 17.1 User modeli
Alanlar:
- id
- username
- email
- elo
- wins
- losses
- draws

### 17.2 Game modeli
Alanlar:
- id
- whitePlayer
- blackPlayer
- currentFen
- pgn
- result
- gameMode
- status
- createdAt

### 17.3 Move modeli
Alanlar:
- moveNumber
- from
- to
- san
- fenAfterMove
- playerId

### 17.4 Profile stats modeli
Alanlar:
- currentElo
- highestElo
- totalGames
- winRate
- wins
- losses
- draws

### 17.5 Analysis modeli
Alanlar:
- moveNumber
- playedMove
- bestMove
- evaluation
- classification
- comment

---

## 18. Enum Yapıları

### 18.1 GameMode
- Offline
- Online

### 18.2 GameType
- VsComputer
- Rated
- Casual

### 18.3 GameStatus
- Waiting
- Active
- Finished
- Aborted

### 18.4 GameResult
- WhiteWin
- BlackWin
- Draw
- None

### 18.5 QueueStatus
- Waiting
- Matched
- Cancelled

### 18.6 MoveClassification
- Best
- Good
- Inaccuracy
- Mistake
- Blunder

---

## 19. API Planı

### 19.1 Auth endpointleri
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`

### 19.2 Profile endpointleri
- `GET /api/profile/me`
- `GET /api/profile/history`
- `GET /api/profile/stats`

### 19.3 Game endpointleri
- `POST /api/games/create-offline`
- `GET /api/games/{id}`
- `GET /api/games/history`
- `POST /api/games/{id}/finish`

### 19.4 Matchmaking endpointleri
- `POST /api/matchmaking/join`
- `POST /api/matchmaking/cancel`
- `POST /api/matchmaking/create-room`
- `POST /api/matchmaking/join-room`

### 19.5 Analysis endpointleri
- `POST /api/analysis/game/{id}`
- `GET /api/analysis/game/{id}`

### 19.6 Health/debug endpointleri
- `GET /api/health`
- `GET /api/version`

---

## 20. SignalR Hub Tasarımı

### 20.1 Hub görevleri
- oyuna bağlanma
- odadan ayrılma
- hamle gönderme
- rakibi bilgilendirme
- oyun bitiş olayını gönderme
- bağlantı kopmasını yönetme

### 20.2 Örnek hub olayları
İstemciden sunucuya:
- `JoinGame`
- `LeaveGame`
- `MakeMove`
- `ResignGame`
- `OfferDraw`

Sunucudan istemciye:
- `GameStarted`
- `MovePlayed`
- `GameUpdated`
- `GameFinished`
- `OpponentDisconnected`

### 20.3 Online oyun akışı
1. kullanıcı eşleşir
2. game room oluşur
3. oyuncular room’a katılır
4. bir oyuncu hamle gönderir
5. backend doğrular
6. move diğer oyuncuya yayınlanır
7. game state güncellenir
8. oyun biterse sonuç yazılır

---

## 21. Satranç Kuralları ve Oyun Mantığı

### 21.1 Zorunlu kurallar
Sistem kesin desteklemelidir:
- normal taş hareketleri
- şah kontrolü
- şah mat
- pat
- rok
- en passant
- piyon terfisi
- hamle sırası

### 21.2 Kural motoru yaklaşımı
- legal move hesaplaması hazır satranç kütüphanesi ile yapılır
- UI sadece mevcut state’i gösterir
- iş mantığı widget içine gömülmez

### 21.3 Oyun state yönetimi
Bir oyunun state’i şunları içermelidir:
- current FEN
- current turn
- move list
- captured pieces
- status
- result

---

## 22. Stockfish Entegrasyon Planı

### 22.1 Nerede kullanılacak?
- bilgisayara karşı oyun
- oyun analizi

### 22.2 Kullanım şekli
#### Offline mod
- kullanıcı hamle yapar
- yeni pozisyon FEN olarak hazırlanır
- Stockfish’e gönderilir
- motor hamlesi alınır
- tahta güncellenir

#### Analiz mod
- oyun hamleleri sırayla değerlendirilir
- her pozisyonda en iyi hamle alınır
- kullanıcının yaptığı hamle ile kıyaslanır
- sınıflandırma yapılır

### 22.3 Zorluk seviyesi
İlk sürüm için basit yaklaşım:
- Easy
- Medium
- Hard

Bu seviyeler motor derinliği ve düşünme süresi ile yönetilebilir.

---

## 23. ELO Sistemi Planı

### 23.1 Amaç
Online rated maçlarda kullanıcının beceri puanını dinamik şekilde değiştirmek.

### 23.2 Kurallar
- her kullanıcı başlangıçta **1000 ELO** ile başlar
- yalnızca **online rated** maçlar ELO etkiler
- offline oyunlar ELO’yu değiştirmez

### 23.3 Sonuç durumları
- kazanma → puan artışı
- kaybetme → puan düşüşü
- beraberlik → küçük fark

### 23.4 Basit formül yaklaşımı
Teslim için basitleştirilmiş mantık yeterlidir. Ancak yapının profesyonel görünmesi için klasik satranç mantığına yakın sistem tercih edilir.

Örnek mantık:
- beklenen skor hesapla
- K sabiti belirle
- yeni puanı buna göre üret

### 23.5 ELO geçmişi
Her rated maç sonunda:
- eski elo
- yeni elo
- fark
- hangi maçta değiştiği

saklanmalıdır.

---

## 24. Hata Yönetimi ve Güvenlik

### 24.1 Auth güvenliği
- şifreler hash’li tutulmalı
- JWT süreli olmalı
- korumalı endpointlere token zorunlu olmalı

### 24.2 Uygulama hata türleri
- ağ hatası
- giriş doğrulama hatası
- eşleşme hatası
- oyun senkronizasyon hatası
- analiz servisi hatası

### 24.3 Kullanıcıya gösterim
- teknik exception metni gösterilmez
- sade hata mesajları kullanılır
- retry mekanizması düşünülebilir

---

## 25. Test Planı

### 25.1 Birim testleri
- ELO hesaplama
- sonuç belirleme
- DTO dönüşümleri

### 25.2 Entegrasyon testleri
- auth akışı
- game create / game finish
- history çekme

### 25.3 Manuel testler
- offline oyun akışı
- online oyun akışı
- web + mobil eşzamanlı test
- oyun sonu kayıt
- analiz ekranı

### 25.4 Sunum testi
Final tesliminden önce şu demo kesin test edilmelidir:
- kayıt ve giriş
- bilgisayara karşı oyun
- online oyunun mobil + web arasında çalışması
- maçın history’de görünmesi
- analizin açılması

---

## 26. Proje Geliştirme Fazları

### Faz 1 — Planlama ve tasarım
Çıktılar:
- proje dokümanı
- ekran listesi
- veri modeli
- klasör yapıları
- mimari kararlar

### Faz 2 — UI iskeleti
Çıktılar:
- boş ekranlar
- route sistemi
- temel component kütüphanesi
- tasarım dili

### Faz 3 — Auth altyapısı
Çıktılar:
- register/login API
- JWT
- Flutter auth ekranları
- token saklama

### Faz 4 — Satranç tahtası ve local logic
Çıktılar:
- board ekranı
- legal moves
- oyun durumu
- hamle listesi

### Faz 5 — Bilgisayara karşı oyun
Çıktılar:
- Stockfish entegrasyonu
- zorluk seçimi
- oyun sonu yönetimi

### Faz 6 — Online oyun
Çıktılar:
- SignalR hub
- matchmaking
- room mantığı
- hamle senkronizasyonu

### Faz 7 — ELO ve geçmiş
Çıktılar:
- sonuç kayıt
- ELO hesaplama
- profile stats
- history ekranı

### Faz 8 — Analiz
Çıktılar:
- maç seçimi
- hamle analizi
- sınıflandırma ekranı

### Faz 9 — Teslim polish
Çıktılar:
- loading / empty / error durumları
- görsel son dokunuşlar
- demo senaryosu

---

## 27. Minimum Viable Product (MVP)

Eğer zaman daralırsa bile teslim edilebilir sürüm şu olmalıdır:

- login/register
- ana sayfa
- satranç tahtası
- bilgisayara karşı oyun
- online eşleşme
- online oyun
- maç geçmişi
- basit ELO
- sade UI

Analiz modülü bu durumda daha hafif tutulabilir ama yine de temel hali olması avantaj sağlar.

---

## 28. Demo Senaryosu

### Demo 1 — Kimlik doğrulama
- kullanıcı kayıt olur
- giriş yapar
- ana sayfa açılır

### Demo 2 — Bilgisayara karşı oyun
- oyun başlatılır
- birkaç hamle oynanır
- motor hamlesi gösterilir
- sonuç alınır

### Demo 3 — Online oyun
- mobil istemci ile giriş
- web istemci ile ikinci kullanıcı girişi
- eşleşme yapılır
- karşılıklı hamleler oynanır
- oyun biter
- sonuç ve ELO değişimi gösterilir

### Demo 4 — Geçmiş ve analiz
- geçmiş maç listesi açılır
- son maç seçilir
- analiz ekranı gösterilir

---

## 29. Sunumda Vurgu Yapılacak Noktalar

Sunum sırasında özellikle şu başlıklar öne çıkarılmalıdır:

- tek kod tabanı ile mobil + web test yapısı
- .NET + SignalR ile gerçek zamanlı oyun
- Stockfish entegrasyonu
- ELO puanlama mantığı
- maç geçmişi ve analiz
- düzenli mimari ve profesyonel dosya yapısı

---

## 30. Nihai Proje Tanımı

Bu proje şu şekilde tanımlanabilir:

> Flutter tabanlı, .NET backend destekli, gerçek zamanlı online maç, bilgisayara karşı oyun, maç geçmişi, ELO sistemi ve temel analiz modülü içeren modern bir mobil satranç uygulaması.

Bu tanım hem akademik hem teknik hem de sunum açısından yeterince güçlüdür.

---

## 31. Kodlamadan Önce Kesinleştirilen Kararlar

Bu dokümana göre şu kararlar netleşmiştir:

- mobil istemci **Flutter** ile geliştirilecek
- web istemci test amaçlı **Flutter Web** olacak
- backend **.NET 8 + ASP.NET Core** olacak
- gerçek zamanlı yapı **SignalR** ile sağlanacak
- oyun kuralları hazır bir **chess kütüphanesi** ile yönetilecek
- tahta hazır bir **Flutter chess board widget** ile gösterilecek
- bilgisayara karşı oyun ve analiz için **Stockfish** kullanılacak
- online rated maçlarda **ELO sistemi** çalışacak
- veritabanında kullanıcı, oyun, hamle ve elo geçmişi tutulacak

---

## 32. Kodlamaya Başlamadan Önce Yapılacak Son Hazırlıklar

Sıradaki adımlar şunlardır:

1. UI wireframe planı çıkarmak
2. ekran bazlı component listesi hazırlamak
3. backend entity ve DTO listesini netleştirmek
4. database migration planı çıkarmak
5. Flutter başlangıç projesini kurmak
6. .NET solution yapısını oluşturmak

---

## 33. Sonuç

Bu doküman, projeye başlamadan önce gereken tüm ana planlama başlıklarını kapsar:

- amaç
- kapsam
- teknoloji seçimi
- mimari
- modüller
- sayfalar
- veri tipleri
- dosya yapıları
- veritabanı tasarımı
- API planı
- gerçek zamanlı yapı
- ELO sistemi
- analiz sistemi
- test ve demo planı

Bu sayede kodlamaya geçildiğinde neyin neden yapıldığı baştan belli olacak ve proje dağılmadan ilerleyebilecektir.
