import mysql from "mysql2/promise";
import dotenv from "dotenv";
dotenv.config();

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function main() {
  let connection;
  for (let attempt = 1; attempt <= 10; attempt++) {
    try {
      connection = await mysql.createConnection({
        host: process.env.DB_HOST || "217.21.85.14",
        port: Number(process.env.DB_PORT) || 3306,
        database: process.env.DB_DATABASE || "nobl6990_Demo1-SD",
        user: process.env.DB_USERNAME || "nobl6990_Demo-SD",
        password: process.env.DB_PASSWORD || "Zqx~(o1ItPp{fx+-",
      });
      break;
    } catch (e) {
      console.warn(`Connection attempt ${attempt} failed: ${e.message}. Waiting 4s...`);
      await sleep(4000);
    }
  }

  if (!connection) {
    throw new Error("Could not connect to MySQL after 10 attempts");
  }

  const tables = [
    "assessments",
    "alumni",
    "graduates",
    "exitRecords",
    "GradebookEntry",
    "GradebookSubmission",
    "Room"
  ];

  try {
    for (const t of tables) {
      const [rows] = await connection.execute(`SELECT id, data, uid FROM \`${t}\` LIMIT 1`);
      console.log(`\nTable ${t} schema:`);
      if (rows.length > 0) {
        console.log(`- ID: ${rows[0].id}`);
        console.log(`- UID: ${rows[0].uid}`);
        console.log(`- Data:`, JSON.parse(rows[0].data));
      } else {
        console.log("- No rows found");
      }
    }
  } catch (error) {
    console.error("Failed:", error);
  } finally {
    await connection.end();
  }
}

main().catch(console.error);
