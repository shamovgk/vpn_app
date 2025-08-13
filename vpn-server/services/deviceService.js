// services/deviceService.js

async function getUserDevicesCount({ userId, db }) {
  const row = await new Promise((resolve, reject) =>
    db.get(
      `SELECT COUNT(*) as count FROM Devices WHERE user_id = ?`,
      [userId],
      (err, row) => err ? reject(err) : resolve(row)
    )
  );
  return row.count;
}

async function getUserDeviceLimit() {
  return 3;
}

module.exports = {
  getUserDevicesCount,
  getUserDeviceLimit,
};