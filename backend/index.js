require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

// Conexión a MongoDB (usar variable de entorno MONGODB_URI)
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/Asistencia';
mongoose
  .connect(mongoUri)
  .then(() => console.log('Conectado a MongoDB'))
  .catch((err) => console.error('Error conectando a MongoDB:', err));

// Modelo de facultad
const FacultadSchema = new mongoose.Schema({
  nombre: String,
  siglas: String
});
const Facultad = mongoose.model('facultades', FacultadSchema);

// Modelo de escuela
const EscuelaSchema = new mongoose.Schema({
  nombre: String,
  siglas: String,
  siglas_facultad: String
});
const Escuela = mongoose.model('escuelas', EscuelaSchema);

// Modelo de asistencias
const AsistenciaSchema = new mongoose.Schema({
  nombre: String,
  apellido: String,
  dni: String,
  codigo_universitario: String,
  siglas_facultad: String,
  siglas_escuela: String,
  tipo: String,
  fecha_hora: Date,
  entrada_tipo: String,
  puerta: String
});
const Asistencia = mongoose.model('asistencias', AsistenciaSchema);

// Ruta para obtener asistencias
app.get('/asistencias', async (req, res) => {
  try {
    const asistencias = await Asistencia.find();
    res.json(asistencias);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener asistencias' });
  }
});

// Modelo de ejemplo
const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String, // Asegúrate de tener este campo
  rango: String     // Opcional, para roles
});
const User = mongoose.model('usuarios', UserSchema);

// Ruta para obtener facultades
app.get('/facultades', async (req, res) => {
  try {
    const facultades = await Facultad.find();
    res.json(facultades);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener facultades' });
  }
});

// Ruta para obtener escuelas por facultad
app.get('/escuelas', async (req, res) => {
  const { siglas_facultad } = req.query;
  try {
    let escuelas;
    if (siglas_facultad) {
      escuelas = await Escuela.find({ siglas_facultad });
    } else {
      escuelas = await Escuela.find();
    }
    res.json(escuelas);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener escuelas' });
  }
});
app.get('/usuarios', async (req, res) => {
  const users = await User.find();
  res.json(users);
});

app.post('/usuarios', async (req, res) => {
  try {
    const body = req.body;
    // Hashear la contraseña antes de guardar
    if (body.password) {
      const salt = await bcrypt.genSalt(10);
      body.password = await bcrypt.hash(body.password, salt);
    }
    const user = new User(body);
    await user.save();
    // No devolver la contraseña
    const u = user.toObject();
    delete u.password;
    res.json(u);
  } catch (err) {
    res.status(500).json({ error: 'Error al crear usuario', details: err.message });
  }
});

// Ruta de login para autenticación con MongoDB
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    // Buscar usuario por email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Usuario no encontrado' });
    }
    // Validar contraseña: soporta contraseñas hasheadas con bcrypt y (temporalmente) texto plano
    let passwordMatches = false;
    if (user.password && user.password.startsWith('$2')) {
      passwordMatches = await bcrypt.compare(password, user.password);
    } else {
      // fallback: comparar texto plano (solo para compatibilidad con datos existentes)
      passwordMatches = user.password === password;
      // si coincide y no está hasheada, re-hashear en segundo plano
      if (passwordMatches) {
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(password, salt);
        await user.save();
      }
    }

    if (!passwordMatches) {
      return res.status(401).json({ error: 'Contraseña incorrecta' });
    }

    // Generar JWT
    const jwtSecret = process.env.JWT_SECRET || 'please_change_this_secret';
    const token = jwt.sign({ id: user._id, email: user.email, rango: user.rango }, jwtSecret, {
      expiresIn: '7d',
    });

    // Enviar datos relevantes (sin contraseña)
    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      rango: user.rango || 'user',
      token,
    });
  } catch (err) {
    res.status(500).json({ error: 'Error en el servidor' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor escuchando en puerto ${PORT}`);
});