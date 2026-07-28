import mysql from "mysql2/promise";
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || "217.21.85.14",
    port: Number(process.env.DB_PORT) || 3306,
    database: process.env.DB_DATABASE || "nobl6990_Demo1-SD",
    user: process.env.DB_USERNAME || "nobl6990_Demo-SD",
    password: process.env.DB_PASSWORD || "Zqx~(o1ItPp{fx+-",
  });

  const tables = ["exitRecords", "alumni", "graduates", "assessments", "Notice", "CalendarEvent", "Homework", "LiveClass"];
  try {
    for (const t of tables) {
      const [rows] = await connection.execute(`SELECT DISTINCT uid FROM \`${t}\``);
      console.log(`Table ${t} distinct uids:`, rows.map(r => r.uid));
    }
  } catch (error) {
    console.error("Failed:", error);
  } finally {
    await connection.end();
  }
}

main().catch(console.error);
