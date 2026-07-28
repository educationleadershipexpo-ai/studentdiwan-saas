import Database from 'better-sqlite3';

const dbPath = 'c:/Users/abish/Downloads/diwan-main/diwan-main/local_database.db';
const db = new Database(dbPath);

console.log('--- Chat Threads ---');
const threads = db.prepare("SELECT * FROM chat_threads").all();
console.log(JSON.stringify(threads, null, 2));

console.log('\n--- Chat Messages ---');
const messages = db.prepare("SELECT * FROM chat_messages ORDER BY createdAt DESC LIMIT 5").all();
console.log(JSON.stringify(messages, null, 2));

db.close();
