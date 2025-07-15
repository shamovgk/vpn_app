const express = require('express');
const session = require('express-session');
const sqlite3 = require('sqlite3').verbose();
const { config } = require('./config/config');
const authRoutes = require('./routes/authRoutes');
const deviceRoutes = require('./routes/deviceRoutes');
const adminRoutes = require('./routes/adminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();
app.set('view engine', 'ejs');
app.set('views', __dirname + '/views');
app.use(express.json());
app.use(session(config.session));

const db = new sqlite3.Database(config.dbPath, (err) => {
  if (err) {
    console.error('Error opening database', err.message);
  } else {
    console.log('Connected to the SQLite database at', config.dbPath);
    require('./models/userModel')(db);
    require('./models/pendingUserModel')(db);
    require('./models/deviceModel')(db);
    require('./models/passwordResetModel')(db);
    require('./models/userStatsModel')(db);
  }
});
app.set('db', db);

app.use('/auth', authRoutes);
app.use('/devices', deviceRoutes);
app.use('/admin', adminRoutes);
app.use('/pay', paymentRoutes);

app.listen(config.port, () => console.log(`Server running on http://localhost:${config.port}`));