const crypto = require('crypto');
const logger = require('../utils/logger.js');

function getCurrentDatePlusDays(days, meta = {}) {
  const date = new Date();
  const milliseconds = days * 24 * 60 * 60 * 1000 + 1000;
  date.setTime(date.getTime() + milliseconds);
  const result = date.toISOString();
  logger.info(`Вызов getCurrentDatePlusDays(${days}) = ${result}`, meta);
  return result;
}

function generateToken(meta = {}) {
  const token = crypto.randomBytes(16).toString('hex');
  logger.info('Генерация токена', { ...meta });
  return token;
}

function generateVerificationCode(meta = {}) {
  const code = crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');

  logger.info('Генерация кода верификации', {
    ...meta,
    code_preview: `${code.slice(0, 2)}****`
  });

  return code;
}

async function generateVpnKey(userId) {
  const scriptPath = __dirname + '/../scripts/generate_vpn_key.sh';
  const configScriptPath = __dirname + '/../scripts/add_to_wg_conf.sh';

  try {
    const { privateKey } = await executeScript(scriptPath);
    logger.info('Сгенерирован приватный ключ WireGuard', { userId });
    const { clientIp } = await executeScript(configScriptPath, [privateKey, String(userId)]);
    logger.info('Назначен IP для клиента WireGuard', { userId, clientIp });
    return { privateKey, clientIp };
  } catch (error) {
    logger.error('Ошибка генерации VPN-ключа', { userId, error: error.message });
    throw new Error(`Failed to generate VPN key: ${error.message}`);
  }
}

function executeScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    const child = require('child_process').spawn('bash', [scriptPath, ...args]);
    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => (stdout += data));
    child.stderr.on('data', (data) => (stderr += data));

    child.on('error', (error) => {
      logger.error('Ошибка запуска bash-скрипта', { scriptPath, args, error: error.message });
      reject(new Error(`Script execution error: ${error.message}`));
    });
    child.on('close', (code) => {
      if (code !== 0) {
        logger.error('Bash-скрипт завершился с ошибкой', { scriptPath, args, code, stderr });
        reject(new Error(`Script failed: exit code ${code}, stderr=${stderr}`));
      } else {
        try {
          logger.info('Bash-скрипт отработал', { scriptPath, args, stdout });
          resolve(JSON.parse(stdout));
        } catch (e) {
          logger.error('Некорректный JSON от bash-скрипта', { scriptPath, args, stdout, stderr });
          reject(new Error(`Invalid JSON output: ${stdout}, stderr=${stderr}`));
        }
      }
    });
  });
}

module.exports = {
  getCurrentDatePlusDays,
  generateToken,
  generateVerificationCode,
  generateVpnKey,
  executeScript
};
