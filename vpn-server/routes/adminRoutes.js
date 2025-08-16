// routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const validate = require('../middlewares/validate');
const { adminLoginSchema, adminUpdateUserSchema } = require('../schemas/adminSchemas');
const withDb = require('../middlewares/withDb');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// req.db для всех /admin
router.use(withDb);

// страницы
router.get('/login', (req, res) => {
  res.render('login', {
    csrfToken: req.csrfToken(),
    title: 'Вход в админку',
    next: req.query.next || ''
  });
});

router.get('/',
  adminController.adminAuth,
  wrap(adminController.listUsersPage)
);

// JSON для SPA-пагинации/сортировки/фильтра
router.get('/users',
  adminController.adminAuth,
  wrap(adminController.listUsersJson)
);

// REST
router.post('/login',
  validate(adminLoginSchema),
  wrap(adminController.adminLogin)
);

router.post('/logout',
  wrap(adminController.adminLogout)
);

router.put('/users/:id',
  adminController.adminAuth,
  validate(adminUpdateUserSchema),
  wrap(adminController.updateUser)
);

router.post('/users/:id/grant-30d',
  adminController.adminAuth,
  wrap(adminController.grant30Days)
);

router.get('/users/:id/devices',
  adminController.adminAuth,
  wrap(adminController.getUserDevices)
);

router.delete('/users/:id/devices/:deviceId',
  adminController.adminAuth,
  wrap(adminController.unlinkDevice)
);

// совместимость со старым /admin/users/search
router.get('/users/search',
  adminController.adminAuth,
  (req, res) => {
    const q = req.query.username || req.query.q || '';
    const s = new URLSearchParams({
      q,
      page: req.query.page || '1',
      limit: req.query.limit || '20'
    });
    return res.redirect(302, '/admin/users?' + s.toString());
  }
);

router.get('/stats',
  adminController.adminAuth,
  wrap(adminController.getStats)
);

module.exports = router;
