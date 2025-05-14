const express = require('express');
const router = express.Router();

const propertyRoutes = require('./properties/routes');
const userRoutes = require('./users/routes');

router.use('/users', userRoutes);
router.use('/properties', propertyRoutes);

module.exports = router; 