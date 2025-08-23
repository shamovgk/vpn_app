// routes/publicRoutes.js
const express = require('express');
const router = express.Router();
const config = require('../config/config');

router.get('/', (req, res) => {
  res.render('landing', { site: config.site, layout: false });
});

router.get('/privacy', (req, res) => {
  res.render('privacy', { site: config.site, layout: false });
});

router.get('/terms', (req, res) => {
  res.render('terms', { site: config.site, layout: false });
});

module.exports = router;
