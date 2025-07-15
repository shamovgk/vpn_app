const crypto = require('crypto');
const { exec } = require('child_process');

function getCurrentDatePlusDays(days) {
  const date = new Date();
  const milliseconds = days * 24 * 60 * 60 * 1000 + 1000;
  date.setTime(date.getTime() + milliseconds);
  const result = date.toISOString();
  console.log(`getCurrentDatePlusDays(${days}) = ${result}`);
  return result;
}

function generateToken() {
  return crypto.randomBytes(16).toString('hex');
}

function generateVerificationCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

async function generateVpnKey(userId, db) {
const scriptPath = '/vpn-server/scripts/generate_vpn_key.sh';
const configScriptPath = '/vpn-server/scripts/add_to_wg_conf.sh';

  try {
    const { privateKey } = await executeScript(scriptPath);
    console.log(`Generated VPN private key for user ID ${userId}`);

    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE Users SET vpn_key = ? WHERE id = ?`,
        [privateKey, userId],
        (err) => (err ? reject(err) : resolve())
      );
    });

    const { clientIp } = await executeScript(configScriptPath, [privateKey, userId.toString()]);
    console.log(`Assigned client IP ${clientIp} to user ID ${userId}`);

    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE Users SET client_ip = ? WHERE id = ?`,
        [clientIp, userId],
        (err) => (err ? reject(err) : resolve())
      );
    });

    return { privateKey, clientIp };
  } catch (error) {
    console.error(`VPN key generation failed for user ID ${userId}: ${error.message}`);
    throw new Error(`Failed to generate VPN key: ${error.message}`);
  }
}

function executeScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    const child = require('child_process').spawn('bash', [scriptPath, ...args], { maxBuffer: 1024 * 1024, encoding: 'utf8' });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => (stdout += data));
    child.stderr.on('data', (data) => (stderr += data));

    child.on('error', (error) => reject(new Error(`Script execution error: ${error.message}`)));
    child.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Script failed: exit code ${code}, stderr=${stderr}`));
      } else {
        try {
          resolve(JSON.parse(stdout));
        } catch (e) {
          reject(new Error(`Invalid JSON output: ${stdout}, stderr=${stderr}`));
        }
      }
    });
  });
}

module.exports = { getCurrentDatePlusDays, generateToken, generateVerificationCode, generateVpnKey, executeScript };