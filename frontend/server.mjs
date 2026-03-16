import { App } from '@tinyhttp/app';
import { cors } from '@tinyhttp/cors';
import { JSONFile } from 'lowdb/node';
import { Low } from 'lowdb';
import { json } from 'milliparsec';
import { Service } from './node_modules/json-server/lib/service.js';
import { parseWhere } from './node_modules/json-server/lib/parse-where.js';

const adapter = new JSONFile('db.json');
const db = new Low(adapter, {});
await db.read();

const service = new Service(db);
const app = new App();

// CORS
app.use(cors());

// Body parser with 50MB limit to handle base64 images
app.use(json({ payloadLimit: 50 * 1024 * 1024 }));

// Logger
app.use((req, res, next) => {
  if (req.url !== '/') {
    console.log(`${new Date().toLocaleTimeString()} ${req.method} ${req.url}`);
  }
  next();
});

// Query parser
app.use((req, res, next) => {
  const url = new URL(req.url, 'http://localhost');
  req.query = Object.fromEntries(url.searchParams.entries());
  next();
});

function parseListParams(req) {
  const url = new URL(req.url, 'http://localhost');
  const params = url.searchParams;
  
  const filterParams = new URLSearchParams();
  for (const [key, value] of params.entries()) {
    if (!['_sort', '_page', '_per_page', '_embed', '_where'].includes(key)) {
      filterParams.append(key, value);
    }
  }
  
  let where = parseWhere(filterParams.toString());
  const rawWhere = params.get('_where');
  if (rawWhere) {
    try {
      where = { ...where, ...JSON.parse(rawWhere) };
    } catch (e) {}
  }

  return {
    where,
    sort: params.get('_sort'),
    page: parseInt(params.get('_page')) || undefined,
    perPage: parseInt(params.get('_per_page')) || undefined,
    embed: params.getAll('_embed')
  };
}

// Routes
app.get('/:name', (req, res) => {
  const { name } = req.params;
  if (!service.has(name)) return res.sendStatus(404);
  
  const opts = parseListParams(req);
  const data = service.find(name, opts);
  res.json(data);
});

app.get('/:name/:id', (req, res) => {
  try {
    const { name, id } = req.params;
    const query = req.query || {};
    const data = service.findById(name, id, query);
    if (data) res.json(data);
    else res.sendStatus(404);
  } catch (e) {
    console.error('Error in GET /:name/:id:', e);
    res.status(500).json({ error: e.message });
  }
});

app.post('/:name', async (req, res) => {
  const { name } = req.params;
  try {
    const data = await service.create(name, req.body);
    res.status(201).json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/:name/:id', async (req, res) => {
  const { name, id } = req.params;
  try {
    const data = await service.updateById(name, id, req.body);
    if (data) res.json(data);
    else res.sendStatus(404);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.patch('/:name/:id', async (req, res) => {
  const { name, id } = req.params;
  try {
    const data = await service.patchById(name, id, req.body);
    if (data) res.json(data);
    else res.sendStatus(404);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/:name/:id', async (req, res) => {
  const { name, id } = req.params;
  try {
    const data = await service.destroyById(name, id, req.query ? req.query._dependent : undefined);
    if (data) res.json(data);
    else res.sendStatus(404);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log('-------------------------------------------------------');
  console.log(`🚀 Custom JSON Server running on http://localhost:${PORT}`);
  console.log(`📦 Payload limit: 50MB (Fixes 500 error for ID photos)`);
  console.log('-------------------------------------------------------');
});
