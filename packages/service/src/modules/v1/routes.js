const express = require('express');
const router = express.Router();

const propertyRoutes = require('./properties/routes');
const userRoutes = require('./users/routes');

router.use('/properties', propertyRoutes);
router.use('/users', userRoutes);

module.exports = router; 