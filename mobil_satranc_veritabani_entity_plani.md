# 🗄️ Mobil Satranç Projesi — Veritabanı & Entity Planı

## 1. Amaç

Bu doküman, satranç uygulamasının backend tarafında kullanılacak veri modeli,
veritabanı tabloları ve entity yapısını netleştirmek için hazırlanmıştır.

---

## 2. Genel Yaklaşım

- İlişkisel veritabanı (PostgreSQL / SQL Server)
- Entity Framework Core ile yönetim
- Normalize edilmiş yapı
- Gereksiz karmaşıklıktan kaçınılmış
- Analiz ve genişletmeye uygun tasarım

---

## 3. Temel Tablolar

## 3.1 Users

Kullanıcı bilgileri

Alanlar:
- Id (GUID)
- Username (string)
- Email (string)
- PasswordHash (string)
- Elo (int)
- Wins (int)
- Losses (int)
- Draws (int)
- CreatedAt (datetime)

---

## 3.2 Games

Oynanan oyunlar

Alanlar:
- Id (GUID)
- WhitePlayerId (GUID)
- BlackPlayerId (GUID)
- GameType (enum: Online, Offline)
- Status (enum: Waiting, Playing, Finished)
- Result (enum: WhiteWin, BlackWin, Draw)
- StartFen (string)
- CurrentFen (string)
- Pgn (text)
- WinnerUserId (GUID)
- StartedAt (datetime)
- EndedAt (datetime)

---

## 3.3 GameMoves

Her hamlenin kaydı

Alanlar:
- Id (GUID)
- GameId (GUID)
- MoveNumber (int)
- PlayerId (GUID)
- FromSquare (string)
- ToSquare (string)
- San (string)
- FenAfterMove (string)
- PlayedAt (datetime)

---

## 3.4 EloHistory

ELO değişim geçmişi

Alanlar:
- Id (GUID)
- UserId (GUID)
- GameId (GUID)
- OldElo (int)
- NewElo (int)
- ChangeAmount (int)
- CreatedAt (datetime)

---

## 3.5 MatchQueue

Online eşleşme kuyruğu

Alanlar:
- Id (GUID)
- UserId (GUID)
- EloSnapshot (int)
- QueuedAt (datetime)
- Status (enum: Waiting, Matched)

---

## 3.6 AnalysisResults

Analiz sonuçları

Alanlar:
- Id (GUID)
- GameId (GUID)
- MoveNumber (int)
- BestMove (string)
- PlayedMove (string)
- Evaluation (float)
- Classification (enum: Best, Good, Mistake, Blunder)

---

## 4. İlişkiler

- Users 1 → N Games
- Games 1 → N GameMoves
- Users 1 → N EloHistory
- Games 1 → N AnalysisResults

---

## 5. Enum Yapıları

## GameType
- Online
- Offline

## GameStatus
- Waiting
- Playing
- Finished

## GameResult
- WhiteWin
- BlackWin
- Draw

## AnalysisClassification
- Best
- Good
- Inaccuracy
- Mistake
- Blunder

---

## 6. Entity (C#) Örnekleri

### User Entity
```csharp
public class User
{
    public Guid Id { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public string PasswordHash { get; set; }
    public int Elo { get; set; } = 1000;
}
```

### Game Entity
```csharp
public class Game
{
    public Guid Id { get; set; }
    public Guid WhitePlayerId { get; set; }
    public Guid BlackPlayerId { get; set; }
    public string Pgn { get; set; }
    public DateTime StartedAt { get; set; }
}
```

---

## 7. Performans Notları

- PGN text olarak tutulmalı
- Move tablosu indekslenmeli (GameId)
- User Elo indexlenmeli
- Game history için pagination kullanılmalı

---

## 8. Genişletilebilirlik

İleride eklenebilir:

- Chat sistemi
- Arkadaş listesi
- Turnuva yapısı
- Leaderboard

---

## 9. Sonuç

Bu yapı:

- sade
- genişletilebilir
- performanslı
- final projesi için yeterli

bir veritabanı tasarımı sunar.
