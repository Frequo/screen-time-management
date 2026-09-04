import { readFile } from 'node:fs/promises';
import { isDeepStrictEqual } from 'node:util';

const args = process.argv.slice(2);
const projectIndex = args.indexOf('--project');
const projectId = projectIndex < 0 ? null : args[projectIndex + 1];
if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId) ||
    args.some((arg, index) => arg !== '--apply' && arg !== '--project' && index !== projectIndex + 1)) {
  throw new Error('Usage: node tools/seed_character_catalog.mjs --project PROJECT_ID [--apply]');
}

const characters = JSON.parse(await readFile(new URL('../assets/characters.json', import.meta.url), 'utf8'));
const ids = new Set();
for (const character of characters) {
  if (typeof character.id !== 'string' || !character.id.trim() || ids.has(character.id) ||
      typeof character.pullable !== 'boolean' || typeof character.hidden !== 'boolean' ||
      !['common', 'rare', 'epic', 'legendary'].includes(character.rarity) ||
      !/^[0-9a-f]{8}$/i.test(character.accent) || 'public' in character) {
    throw new Error(`Invalid character: ${character.id}`);
  }
  for (const field of ['name', 'title', 'description']) {
    if (typeof character[field] !== 'string') throw new Error(`Missing ${field}: ${character.id}`);
  }
  for (const field of ['portraitUrl', 'mainUrl']) {
    if (character[field] != null && new URL(character[field]).protocol !== 'https:') {
      throw new Error(`Expected HTTPS ${field}: ${character.id}`);
    }
  }
  ids.add(character.id);
}

const document = { schemaVersion: 1, characters };
console.log(JSON.stringify({
  projectId,
  document: 'catalog/characters',
  mode: args.includes('--apply') ? 'create' : 'dry-run',
  characters: characters.length,
  visible: characters.filter((character) => !character.hidden).map((character) => character.id),
  pullable: characters.filter((character) => !character.hidden && character.pullable).map((character) => character.id),
}, null, 2));

if (args.includes('--apply')) {
  const { initializeApp, applicationDefault, deleteApp } = await import('firebase-admin/app');
  const { getFirestore, FieldValue } = await import('firebase-admin/firestore');
  const app = initializeApp({ projectId, credential: applicationDefault() });
  try {
    const reference = getFirestore(app).doc('catalog/characters');
    // First-time migration only: never overwrite an existing live catalog.
    await reference.create({ ...document, updatedAt: FieldValue.serverTimestamp() });
    const saved = (await reference.get()).data();
    if (saved?.schemaVersion !== 1 || !isDeepStrictEqual(saved.characters, characters)) {
      throw new Error('Catalog readback mismatch');
    }
    console.log(`Verified ${saved.characters.length} characters in ${reference.path}.`);
  } finally {
    await deleteApp(app);
  }
}
