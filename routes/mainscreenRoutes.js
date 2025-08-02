const express = require('express');
const router = express.Router();

router.get('/mainscreen', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="ru">
    <head>
      <meta charset="UTF-8">
      <title>Оплата завершена</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 60px; }
        #countdown { font-size: 2em; color: #4CAF50; }
      </style>
    </head>
    <body>
      <h2>Оплата прошла успешно!</h2>
      <p>Окно закроется через <span id="countdown">3</span> сек.</p>
      <script>
        let seconds = 3;
        const countdownEl = document.getElementById('countdown');
        const timer = setInterval(() => {
          seconds--;
          countdownEl.textContent = seconds;
          if (seconds <= 0) {
            clearInterval(timer);
            // Для большинства WebView и браузеров:
            window.close();
            // В случае если window.close() не сработал, можно добавить редирект:
            setTimeout(() => { window.location.href = "about:blank"; }, 500);
          }
        }, 1000);
      </script>
    </body>
    </html>
  `);
});

module.exports = router;
