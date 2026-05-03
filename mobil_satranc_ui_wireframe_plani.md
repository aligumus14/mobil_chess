# ♟️ Mobil Satranç Projesi — UI Wireframe ve Tasarım Planı

## 1. Amaç

Bu doküman, mobil satranç projesinin kullanıcı arayüzü tarafını kodlamaya başlamadan önce netleştirmek için hazırlanmıştır.

Amaç:
- sade
- modern
- anlaşılır
- hocanın dikkat edeceği tasarım kalitesine uygun
- mobil öncelikli
- gerektiğinde web test istemcisinde de düzgün çalışan

bir arayüz sistemi kurmaktır.

---

## 2. Tasarım Prensipleri

## 2.1 Genel yaklaşım
Arayüz şu özelliklere sahip olmalıdır:

- sade görünüm
- göz yormayan renk kullanımı
- net hiyerarşi
- büyük ve anlaşılır butonlar
- satranç tahtasını merkeze alan yerleşim
- kullanıcıyı yönlendiren akış
- gereksiz kalabalıktan uzak ekranlar

## 2.2 UI/UX hedefleri
- Kullanıcı ilk açılışta ne yapacağını hemen anlamalı
- Online ve offline modlar açık şekilde ayrılmalı
- Oyun ekranı odak noktası olmalı
- Profil ve geçmiş ekranları bilgi yoğun ama düzenli olmalı
- Analiz ekranı teknik ama sade kalmalı

---

## 3. Görsel Kimlik

## 3.1 Tasarım dili
Önerilen tasarım dili:

- minimal
- premium hissiyatlı
- modern kart yapısı
- yumuşak köşeler
- dengeli boşluk kullanımı
- net ikonografi
- az ama etkili vurgu renkleri

## 3.2 Renk paleti önerisi
Ana palet:

- Ana renk: koyu lacivert veya antrasit
- Vurgu rengi: altın sarısı / mavi / zümrüt
- Arka plan: açık gri veya kırık beyaz
- Başarı: yeşil
- Hata / yenilgi: kırmızı
- Nötr yüzeyler: beyaz, açık gri, koyu gri

Örnek yaklaşım:
- Background: #F5F7FA
- Surface: #FFFFFF
- Primary: #1E2A38
- Accent: #D4A017
- Success: #22C55E
- Danger: #EF4444
- Text Primary: #111827
- Text Secondary: #6B7280

## 3.3 Tipografi
- Başlıklar güçlü ve belirgin
- Alt başlıklar sade
- Buton metinleri kısa ve net
- Oyun sırasında çok küçük font kullanılmamalı

Öneri:
- Başlık: 24–30
- Alt başlık: 18–22
- Gövde metni: 14–16
- Küçük bilgi metni: 12–13

---

## 4. Navigasyon Yapısı

## 4.1 Ana navigasyon
Uygulamada ana akış için alt menü veya ana sayfa kart yapısı kullanılabilir.

En uygun yaklaşım:
- açılış sonrası ana sayfada kart bazlı yönlendirme
- alt menüde temel sekmeler

Önerilen alt menü:
- Ana Sayfa
- Geçmiş
- Analiz
- Profil

Online ve Offline oyun ana sayfadan başlatılabilir.

## 4.2 Route yapısı
Örnek route yapısı:

- /splash
- /login
- /register
- /home
- /play/offline
- /play/online
- /matchmaking
- /game/online/:id
- /history
- /history/:id
- /analysis
- /analysis/:gameId
- /profile
- /settings

---

## 5. Sayfa Bazlı Wireframe Planı

## 5.1 Splash Screen

### Amaç
- uygulama logosunu göstermek
- kısa yükleme deneyimi sunmak
- kullanıcıyı auth kontrolüne yönlendirmek

### İçerik
- ortada logo
- uygulama adı
- altta kısa slogan
- loading indicator

### Wireframe
- üst boş alan
- merkezde logo
- altında uygulama adı
- en altta küçük yükleniyor göstergesi

---

## 5.2 Login Screen

### Amaç
Kullanıcının giriş yapması

### İçerik
- logo
- hoş geldin başlığı
- email alanı
- şifre alanı
- giriş yap butonu
- kayıt ol linki
- misafir modu varsa ikincil buton

### Wireframe
- üstte küçük logo
- ortada form kartı
- input alanları dikey
- ana CTA: Giriş Yap
- alt metin: Hesabın yok mu? Kayıt ol

### UX Notları
- form validasyonu net olmalı
- hata mesajları input altında görünmeli
- loading durumunda buton disable edilmeli

---

## 5.3 Register Screen

### Amaç
Yeni kullanıcı oluşturma

### İçerik
- kullanıcı adı
- email
- şifre
- şifre tekrar
- kayıt ol butonu

### Wireframe
- login ekranına benzer
- tek fark daha fazla input alanı

### UX Notları
- şifre kuralları gösterilebilir
- hatalı alanlar net belirtilmeli

---

## 5.4 Home Screen

### Amaç
Kullanıcıyı sistemin ana özelliklerine yönlendirmek

### Ana Bölümler
- üst karşılama alanı
- elo kartı
- hızlı aksiyon kartları
- son maçlar özeti
- istatistik özeti

### İçerik
- kullanıcı adı
- mevcut elo
- toplam galibiyet / mağlubiyet / beraberlik
- butonlar:
  - Bilgisayara Karşı Oyna
  - Online Oyna
  - Oyun Analizi
  - Geçmiş Maçlar

### Wireframe
1. Üst header
   - selamlama
   - profil avatarı
2. Elo bilgi kartı
3. 2x2 aksiyon kart grid
4. Son maçlar listesi
5. Küçük performans özeti

### UX Notları
- ana özellikler tek bakışta görünmeli
- kullanıcı kaybolmamalı
- kartlar dokunmatik uyumlu büyük olmalı

---

## 5.5 Offline Oyun Hazırlık Ekranı

### Amaç
Bilgisayara karşı maç başlamadan önce ayar seçmek

### İçerik
- zorluk seviyesi
- oyuncu rengi
- süreli / süresiz seçenek
- oyunu başlat butonu

### Wireframe
- üstte başlık
- kart içinde ayarlar
- altta büyük Başlat butonu

---

## 5.6 Offline Game Screen

### Amaç
Kullanıcının bilgisayara karşı satranç oynaması

### Ana Yerleşim
- üst bilgi barı
- merkezde satranç tahtası
- altta hamle listesi / aksiyonlar

### İçerik
- rakip adı: Stockfish / Bot
- kullanıcı adı
- kalan süre varsa zaman göstergesi
- tahta
- son hamle vurgusu
- hamle geçmişi
- butonlar:
  - yeni oyun
  - geri al
  - teslim ol
  - analiz et

### Wireframe
1. Top info area
   - rakip bilgisi
   - bot seviyesi
2. Chess board area
3. Bottom control area
   - hamle listesi
   - aksiyon butonları

### UX Notları
- ekranda en baskın unsur tahta olmalı
- fazla bilgi üst üste binmemeli
- mobilde kontroller başparmak erişimine uygun olmalı

---

## 5.7 Online Matchmaking Screen

### Amaç
Kullanıcıyı online rakiple eşleştirmek

### İçerik
- mevcut elo
- hızlı eşleşme butonu
- oda oluştur butonu
- oda kodu ile katıl alanı
- bekleme animasyonu

### Wireframe
- üstte elo kartı
- ortada büyük Hızlı Eşleş butonu
- altında “veya”
- oda oluştur / katıl alanları

### UX Notları
- hızlı eşleşme temel CTA olmalı
- test için oda kodu akışı basit tutulmalı

---

## 5.8 Online Game Screen

### Amaç
İki oyuncunun gerçek zamanlı maç yapması

### İçerik
- oyuncu bilgileri
- elo bilgisi
- kalan süre
- bağlantı durumu
- satranç tahtası
- hamle listesi
- oyun aksiyonları:
  - beraberlik teklif et
  - teslim ol
  - oyundan çık

### Wireframe
1. Top opponent panel
2. Chess board
3. Self panel
4. Bottom tab / accordion:
   - hamle listesi
   - sohbet yoksa analiz önizlemesi gerekmez
5. Secondary actions row

### UX Notları
- sıra kimde net görünmeli
- bağlantı kopması durumunda kullanıcı bilgilendirilmeli
- rakip hamlesi geldiğinde görsel geri bildirim olmalı

---

## 5.9 Game Result Modal / Screen

### Amaç
Maç sonucunu sade ama etkili göstermek

### İçerik
- sonuç başlığı:
  - Kazandın
  - Kaybettin
  - Berabere
- skor özeti
- elo değişimi
- tekrar oyna
- ana sayfa
- analiz et

### Wireframe
- ortada sonuç kartı
- üstte ikon / durum göstergesi
- altında butonlar

---

## 5.10 Match History Screen

### Amaç
Geçmiş maçları listelemek

### İçerik
- filtreler:
  - online / offline
  - kazanılan / kaybedilen / beraberlik
- maç kartları
- tarih
- rakip
- sonuç
- renk
- analiz et butonu

### Wireframe
- üstte başlık
- filtre chip’leri
- altında scroll kart listesi

### Kart İçeriği
- rakip adı
- tarih
- maç tipi
- sonuç badge
- kısa elo etkisi
- “detay” veya “analiz” butonu

---

## 5.11 Match Detail Screen

### Amaç
Bir maçın detayını göstermek

### İçerik
- oyuncular
- sonuç
- PGN hamle listesi
- final pozisyon
- analiz başlat
- tekrar oynat

### Wireframe
- üstte maç özeti kartı
- ortada küçük tahta veya final board
- altta hamle listesi

---

## 5.12 Analysis Screen

### Amaç
Bir oyunun analizini göstermek

### İçerik
- tahta
- hamle listesi
- seçilen hamlenin değerlendirmesi
- en iyi hamle
- oynanan hamle
- sınıflandırma:
  - Best
  - Good
  - Inaccuracy
  - Mistake
  - Blunder

### Wireframe
1. Analysis summary card
2. Board
3. Move timeline/list
4. Evaluation detail panel

### UX Notları
- çok karmaşık motor verisi göstermeyelim
- final projesi için sade ama etkileyici sunum yeterli
- renkli etiketler analiz okunabilirliğini artırır

---

## 5.13 Profile Screen

### Amaç
Kullanıcının genel bilgilerini ve istatistiklerini göstermek

### İçerik
- avatar
- kullanıcı adı
- email
- elo puanı
- toplam maç
- galibiyet / mağlubiyet / beraberlik
- win rate
- son elo değişimleri

### Wireframe
- üstte profil header kartı
- ortada istatistik kart grid
- altta son aktiviteler

---

## 5.14 Settings Screen

### Amaç
Temel ayarları toplamak

### İçerik
- tema seçimi
- bildirim ayarları
- ses efektleri
- çıkış yap

Final projesi için çok büyük tutulmamalı.

---

## 6. Bileşen Kütüphanesi Planı

## 6.1 Ortak bileşenler
Uygulamada ortak kullanılacak componentler:

- PrimaryButton
- SecondaryButton
- AppTextField
- AppCard
- SectionTitle
- StatCard
- EloBadge
- ResultBadge
- EmptyState
- LoadingView
- ErrorView
- ChessActionButton

## 6.2 Satranç özel bileşenleri
- ChessBoardContainer
- MoveHistoryPanel
- PlayerInfoCard
- TimerWidget
- CapturedPiecesRow
- AnalysisTag
- MatchResultCard

---

## 7. Responsive Yaklaşım

Bu proje mobil öncelikli olacak.
Ama Flutter Web test istemcisi için de bazı uyarlamalar düşünülmeli.

## Mobil
- tek sütun
- alt menü
- tam ekran oyun

## Web
- geniş ekranda board + side panel düzeni
- hamle listesi sağ tarafta olabilir
- test için iki istemciyi yan yana görmeye uygun olabilir

---

## 8. Durum Bazlı Tasarım

## 8.1 Loading durumları
- skeleton veya spinner
- özellikle login, matchmaking ve analysis ekranlarında gerekli

## 8.2 Boş durumlar
Örnek:
- Henüz maçın yok
- Henüz analiz yapılmadı
- Geçmiş bulunamadı

## 8.3 Hata durumları
Örnek:
- bağlantı koptu
- rakip bulunamadı
- analiz alınamadı
- giriş başarısız

Bu durumlar sade ve anlaşılır mesajlarla gösterilmeli.

---

## 9. Kullanıcı Deneyimi Detayları

## 9.1 Geri bildirimler
- buton basımlarında hafif animasyon
- maç sonucu sonrası net geri bildirim
- online rakip bulunduğunda görsel sinyal
- hamle yapıldığında son kare vurgusu

## 9.2 Mikro etkileşimler
- kart hover etkisi webde
- basit geçiş animasyonları
- modal açılış animasyonları
- sıra değiştiğinde hafif highlight

## 9.3 Bildirim mantığı
- online rakip bulundu
- maç bitti
- bağlantı durumu değişti
- analiz tamamlandı

---

## 10. Tasarımda Kaçınılacak Şeyler

- çok fazla renk
- gereksiz gölge kullanımı
- kalabalık ana sayfa
- küçük dokunma alanları
- oyun ekranında aşırı bilgi yığını
- teknik analiz ekranını çok karmaşık yapmak

---

## 11. Tasarım Sistemi Token Planı

## Spacing
- xs: 4
- sm: 8
- md: 12
- lg: 16
- xl: 24
- xxl: 32

## Radius
- small: 8
- medium: 12
- large: 16
- xl: 20

## Shadow
- düşük yoğunluklu, yumuşak kart gölgeleri

## Buton boyutları
- küçük
- orta
- büyük

Ana CTA’larda büyük boy önerilir.

---

## 12. UI Geliştirme Öncelik Sırası

1. Splash
2. Login
3. Register
4. Home
5. Offline setup
6. Offline game
7. Online matchmaking
8. Online game
9. Match result modal
10. Match history
11. Match detail
12. Analysis
13. Profile
14. Settings

---

## 13. Sunum İçin Görsel Olarak En Güçlü Ekranlar

Sunumda özellikle iyi görünmesi gereken ekranlar:

- Home Screen
- Offline/Online Game Screen
- Online Matchmaking Screen
- Analysis Screen
- Profile Screen

Bu sayfalarda ekstra özen gösterilmeli.

---

## 14. Sonuç

Bu UI wireframe planı sayesinde proje başlamadan önce:

- hangi sayfaların olacağı
- her sayfada hangi öğelerin bulunacağı
- nasıl bir tasarım dili kullanılacağı
- mobil ve web uyumu
- ortak bileşen sistemi
- kullanıcı deneyimi yaklaşımı

netleşmiş olur.

Bu doküman, tasarım geliştirme ve Flutter ekran kodlaması sırasında referans doküman olarak kullanılacaktır.
