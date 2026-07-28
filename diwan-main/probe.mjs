import 'dotenv/config';
import mysql from 'mysql2/promise';
const c = await mysql.createConnection({
  host: process.env.DB_HOST, port: +(process.env.DB_PORT||3306),
  user: process.env.DB_USER || process.env.DB_USERNAME, password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE || process.env.DB_NAME
});
const [tabs] = await c.query("SHOW TABLES");
const key = Object.keys(tabs[0])[0];
const names = tabs.map(t=>t[key]).filter(n=>/student|enroll|section|class/i.test(n));
console.log('CANDIDATE_TABLES', names.join(', '));
// sample the Student entity table if present
for (const t of ['Student','students']) {
  try {
    const [r] = await c.query(`SELECT data FROM \`${t}\` LIMIT 1`);
    if (r.length) { const d=JSON.parse(r[0].data); console.log(t,'KEYS', Object.keys(d).join(',')); console.log(t,'SAMPLE', JSON.stringify({name:d.name,grade:d.grade,section:d.section,userId:d.userId,email:d.email,rollNumber:d.rollNumber})); }
  } catch(e){ /* table shape differs */ }
}
await c.end();
