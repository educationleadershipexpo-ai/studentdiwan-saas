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

  try {
    const [tables] = await connection.execute("SHOW TABLES");
    console.log("Database tables list and row counts:");

    const dbName = process.env.DB_DATABASE || "nobl6990_Demo1-SD";
    const key = `Tables_in_${dbName}`;

    for (const t of tables) {
      const tableName = t[key];
      try {
        const [[countResult]] = await connection.execute(`SELECT COUNT(*) as count FROM \`${tableName}\``);
        console.log(`- ${tableName}: ${countResult.count} rows`);
      } catch (e) {
        console.log(`- ${tableName}: Error counting rows (${e.message})`);
      }
    }
  } catch (error) {
    console.error("Failed:", error);
  } finally {
    await connection.end();
  }
}

main().catch(console.error);
