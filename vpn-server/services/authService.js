const bcrypt = require('bcrypt');
const {
  generateToken,
  generateVerificationCode,
  generateVpnKey,
} = require('../utils/utils');

async function registerUser({ username, password, email, db }) {
  const normalizedEmail = email.toLowerCase();
  // Проверки и очистка PendingUsers
  await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM PendingUsers WHERE verification_expiry < ?`,
      [new Date().toISOString()],
      err => err ? reject(err) : resolve()
    )
  );

  // Уже есть юзер или заявка?
  const existingUser = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM Users WHERE username = ? OR email = ?`,
      [username, normalizedEmail],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (existingUser) throw new Error('USER_EXISTS');

  const existingPending = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM PendingUsers WHERE username = ? OR email = ?`,
      [username, normalizedEmail],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (existingPending) throw new Error('PENDING_EXISTS');

  const hashedPassword = bcrypt.hashSync(password, 10);
  const verificationCode = generateVerificationCode({ username });
  const verificationExpiry = new Date(Date.now() + 15 * 60 * 1000).toISOString();

  const pendingId = await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO PendingUsers (username, password, email, verification_code, verification_expiry)
       VALUES (?, ?, ?, ?, ?)`,
      [username, hashedPassword, normalizedEmail, verificationCode, verificationExpiry],
      function (err) { err ? reject(err) : resolve(this.lastID); }
    )
  );

  return { pendingId, username, normalizedEmail, verificationCode };
}

async function verifyEmail({ username, email, verificationCode, db }) {
  const pendingUser = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, verification_code, verification_expiry, password FROM PendingUsers WHERE username = ? AND email = ?`,
      [username, email],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!pendingUser) throw new Error('PENDING_NOT_FOUND');
  if (pendingUser.verification_code !== verificationCode) throw new Error('CODE_INVALID');
  if (new Date(pendingUser.verification_expiry) < new Date()) throw new Error('CODE_EXPIRED');

  // Генерим VPN-ключ при создании юзера
  const { privateKey, clientIp } = await generateVpnKey(pendingUser.id, db);
  // Создаём пользователя
  const userId = await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO Users (username, password, email, vpn_key, client_ip)
       VALUES (?, ?, ?, ?, ?)`,
      [username, pendingUser.password, email, privateKey, clientIp],
      function (err) { err ? reject(err) : resolve(this.lastID); }
    )
  );

  await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id],
      err => err ? reject(err) : resolve()
    )
  );

  return { userId, username, email, clientIp };
}

async function loginUser({ username, password, db }) {
  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username, password, email_verified, vpn_key FROM Users WHERE username = ?`,
      [username],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) throw new Error('USER_NOT_FOUND');
  if (!bcrypt.compareSync(password, user.password)) throw new Error('PASSWORD_INVALID');

  const token = generateToken({ userId: user.id, username });
  const tokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET auth_token = ?, token_expiry = ? WHERE id = ?`,
      [token, tokenExpiry, user.id],
      err => err ? reject(err) : resolve()
    )
  );

  return {
    token,
    user: {
      id: user.id,
      username: user.username,
      email_verified: user.email_verified,
      vpn_key: user.vpn_key || null,
    }
  };
}

async function validateToken({ token, db }) {
  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username, email_verified, vpn_key FROM Users WHERE auth_token = ? AND token_expiry > ?`,
      [token, new Date().toISOString()],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) throw new Error('TOKEN_INVALID');
  return user;
}

async function logout({ token, db }) {
  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username FROM Users WHERE auth_token = ?`,
      [token],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) throw new Error('TOKEN_NOT_FOUND');

  const result = await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE auth_token = ?`,
      [token],
      function (err) { err ? reject(err) : resolve(this.changes); }
    )
  );
  if (result === 0) throw new Error('TOKEN_NOT_FOUND');

  return { userId: user.id, username: user.username };
}

async function forgotPassword({ username, db, sendEmail }) {
  const user = await new Promise((resolve, reject) =>
    db.get(`SELECT id, email FROM Users WHERE username = ?`, [username], (err, user) =>
      err ? reject(err) : resolve(user))
  );
  if (!user) throw new Error('USER_NOT_FOUND');

  const resetCode = generateVerificationCode({ userId: user.id, username });
  const expiryDate = new Date(Date.now() + 15 * 60 * 1000).toISOString();

  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO PasswordReset (email, reset_code, expiry_date) VALUES (?, ?, ?)`,
      [user.email, resetCode, expiryDate],
      err => err ? reject(err) : resolve()
    )
  );

  // Передаем отправку email в контроллер (чтобы сервис был чистый)
  await sendEmail({ email: user.email, resetCode });

  return { userId: user.id, username, email: user.email };
}

async function resetPassword({ username, resetCode, newPassword, db }) {
  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, email FROM Users WHERE username = ?`,
      [username],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) throw new Error('USER_NOT_FOUND');
  const email = user.email;

  const reset = await new Promise((resolve, reject) =>
    db.get(
      `SELECT * FROM PasswordReset WHERE email = ? AND reset_code = ? AND expiry_date > ?`,
      [email, resetCode, new Date().toISOString()],
      (err, row) => err ? reject(err) : resolve(row)
    )
  );
  if (!reset) throw new Error('RESET_INVALID');

  const hashedPassword = bcrypt.hashSync(newPassword, 10);
  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET password = ? WHERE username = ?`,
      [hashedPassword, username],
      err => err ? reject(err) : resolve()
    )
  );
  await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`,
      [email, resetCode],
      err => err ? reject(err) : resolve()
    )
  );
  return { userId: user.id, username };
}

async function getUserByToken({ token, db }) {
  return await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username, vpn_key, client_ip FROM Users WHERE auth_token = ? AND token_expiry > ?`,
      [token, new Date().toISOString()],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
}

module.exports = {
  registerUser,
  verifyEmail,
  loginUser,
  validateToken,
  logout,
  forgotPassword,
  resetPassword,
  getUserByToken,
};