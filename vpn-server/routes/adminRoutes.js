const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const validate = require('../middlewares/validate');
const { adminLoginSchema, adminUpdateUserSchema } = require('../schemas/adminSchemas');
const withDb = require('../middlewares/withDb');

// Все запросы на admin получают req.db
router.use(withDb);

// Формы получают csrfToken (если используется ejs)
router.get('/login', (req, res) => {
  res.render('login', { csrfToken: req.csrfToken(), title: 'Вход в админку' });
});
router.get('/', adminController.adminAuth, async (req, res) => {
  const users = await adminController.getUsers(req, res, true); // Передаем специальный флаг для возврата массива, а не res.render
  if (Array.isArray(users)) {
    res.render('admin', { users, csrfToken: req.csrfToken(), title: 'Admin Panel' });
  }
});

// REST endpoints
router.post('/login', validate(adminLoginSchema), adminController.adminLogin);
router.post('/logout', adminController.adminLogout);
router.put('/users/:id', adminController.adminAuth, validate(adminUpdateUserSchema), adminController.updateUser);
router.get('/users/search', adminController.adminAuth, adminController.searchUsers);
router.get('/stats', adminController.adminAuth, adminController.getStats);

module.exports = router;
