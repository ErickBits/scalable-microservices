require('dotenv').config();
const mongoose = require('mongoose');
const app = require('./app');

const PORT = process.env.PORT || 3002;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/products';

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log('[products-service] Connected to MongoDB');
    app.listen(PORT, () => console.log(`[products-service] Running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('[products-service] MongoDB connection error:', err.message);
    process.exit(1);
  });
