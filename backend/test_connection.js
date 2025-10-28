require('dotenv').config();
const mongoose = require('mongoose');

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('ERROR: MONGODB_URI no está definido en .env');
    process.exit(1);
  }

  try {
    console.log('Conectando a MongoDB...');
    await mongoose.connect(uri);
    console.log('Conectado. Base de datos:', mongoose.connection.name);

    const cols = await mongoose.connection.db.listCollections().toArray();
    console.log('Colecciones en la base de datos:', cols.map(c => c.name).join(', ') || '<ninguna>');

    try {
      const count = await mongoose.connection.db.collection('usuarios').countDocuments();
      console.log('Cantidad de documentos en `usuarios`:', count);
    } catch (e) {
      console.log('Colección `usuarios` no encontrada o error al contar:', e.message);
    }
  } catch (err) {
    console.error('Error conectando a MongoDB:', err.message);
    process.exitCode = 2;
  } finally {
    await mongoose.disconnect();
    console.log('Desconectado.');
  }
}

main();
