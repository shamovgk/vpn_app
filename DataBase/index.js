const sqlite3 = require('sqlite3').verbose();
const express = require('express');
const bcrypt = require('bcrypt');
const path = require('path');

const app = express();
app.use(express.json());

// Путь к базе данных (локальный файл на Windows)
const dbPath = path.join(__dirname, 'vpn.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database', err.message);
  } else {
    console.log('Connected to the SQLite database at', dbPath);
    createTables();
  }
});

// Создание таблиц
function createTables() {
  db.serialize(() => {
    db.run(`
      CREATE TABLE IF NOT EXISTS Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        is_paid BOOLEAN DEFAULT FALSE
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS Keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        client_private_key TEXT NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        FOREIGN KEY (user_id) REFERENCES Users(id)
      )
    `);
  });
}

// Регистрация нового пользователя
app.post('/register', (req, res) => {
  const { username, password } = req.body;
  const hashedPassword = bcrypt.hashSync(password, 10); // Хеширование пароля

  db.run(
    `INSERT INTO Users (username, password) VALUES (?, ?)`,
    [username, hashedPassword],
    function (err) {
      if (err) {
        return res.status(400).json({ error: err.message });
      }
      res.json({ id: this.lastID, username });
    }
  );
});

// Добавление ключа для пользователя (семейная подписка)
app.post('/add-key', (req, res) => {
  const { user_id, client_private_key } = req.body;

  db.run(
    `INSERT INTO Keys (user_id, client_private_key) VALUES (?, ?)`,
    [user_id, client_private_key],
    function (err) {
      if (err) {
        return res.status(400).json({ error: err.message });
      }
      res.json({ id: this.lastID, user_id, client_private_key });
    }
  );
});

// Проверка оплаты и получение активных ключей
app.get('/user/:username', (req, res) => {
  const { username } = req.params;

  db.get(
    `SELECT id, username, is_paid FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: 'User not found' });
      }

      db.all(
        `SELECT client_private_key FROM Keys WHERE user_id = ? AND is_active = TRUE`,
        [user.id],
        (err, keys) => {
          if (err) {
            return res.status(500).json({ error: err.message });
          }
          res.json({ ...user, keys: keys.map(k => k.client_private_key) });
        }
      );
    }
  );
});

// Обновление статуса оплаты
app.put('/pay/:username', (req, res) => {
  const { username } = req.params;

  db.run(
    `UPDATE Users SET is_paid = TRUE WHERE username = ?`,
    [username],
    function (err) {
      if (err) {
        return res.status(400).json({ error: err.message });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json({ message: 'Payment status updated' });
    }
  );
});

// Запуск сервера
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});