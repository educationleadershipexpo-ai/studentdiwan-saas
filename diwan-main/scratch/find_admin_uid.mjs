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
    const [rows] = await connection.execute("SELECT id, data, uid FROM users");
    console.log("Searching user JSON data...");
    for (const row of rows) {
      try {
        const dataObj = typeof row.data === "string" ? JSON.parse(row.data) : row.data;
        if (dataObj && (dataObj.email === "educationleadershipexpo@gmail.com" || dataObj.email === "admin@eduerp.com")) {
          console.log(`Match: email=${dataObj.email}, id=${row.id}, uid=${row.uid}`);
        }
      } catch (e) {
        // Skip invalid JSON
      }
    }
  } catch (error) {
    console.error("Failed:", error);
  } finally {
    await connection.end();
  }
}

main().catch(console.error);
