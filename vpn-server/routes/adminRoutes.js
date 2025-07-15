const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

router.post('/login', (req, res, next) => {
  req.db = req.app.get('db');
  adminController.adminLogin(req, res);
});

router.post('/logout', (req, res, next) => {
  req.db = req.app.get('db');
  adminController.adminLogout(req, res);
});

router.get('/login', (req, res, next) => {
  req.db = req.app.get('db');
  adminController.adminLoginPage(req, res);
});

router.get('/', adminController.adminAuth, (req, res, next) => {
  req.db = req.app.get('db');
  adminController.adminPage(req, res);
});

router.put('/users/:id', adminController.adminAuth, (req, res, next) => {
  req.db = req.app.get('db');
  adminController.updateUser(req, res);
});

router.get('/users/search', adminController.adminAuth, (req, res, next) => {
  req.db = req.app.get('db');
  adminController.searchUsers(req, res);
});

router.get('/stats', adminController.adminAuth, (req, res, next) => {
  req.db = req.app.get('db');
  adminController.getStats(req, res);
});

module.exports = router;