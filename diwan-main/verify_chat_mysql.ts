import mysql from 'mysql2/promise';

async function main() {
  const connection = await mysql.createConnection({
    host: '217.21.85.14',
    user: 'nobl6990_Demo-SD',
    password: 'Zqx~(o1ItPp{fx+-',
    database: 'nobl6990_Demo1-SD',
    port: 3306,
  });

  try {
    console.log('--- Chat Threads ---');
    const [threads] = await connection.execute("SELECT * FROM chat_threads");
    console.log(JSON.stringify(threads, null, 2));

    console.log('\n--- Chat Messages ---');
    const [messages] = await connection.execute("SELECT * FROM chat_messages ORDER BY createdAt DESC LIMIT 5");
    console.log(JSON.stringify(messages, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    await connection.end();
  }
}

main();
