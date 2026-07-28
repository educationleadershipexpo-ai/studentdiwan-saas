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

  try {
    const [students] = await connection.execute("SELECT id, data FROM students LIMIT 10");
    console.log("Students Sample:");
    students.forEach(s => {
      const obj = typeof s.data === "string" ? JSON.parse(s.data) : s.data;
      console.log(`- ID: ${s.id}, Name: ${obj.name || obj.displayName}, Grade: ${obj.grade}, Section: ${obj.section}`);
    });

    const [staff] = await connection.execute("SELECT id, data FROM staff LIMIT 5");
    console.log("\nStaff Sample:");
    staff.forEach(st => {
      const obj = typeof st.data === "string" ? JSON.parse(st.data) : st.data;
      console.log(`- ID: ${st.id}, Name: ${obj.name || obj.displayName}, Role: ${obj.role || obj.designation}`);
    });

    const [subjects] = await connection.execute("SELECT id, data FROM subjects LIMIT 5");
    console.log("\nSubjects Sample:");
    subjects.forEach(sub => {
      const obj = typeof sub.data === "string" ? JSON.parse(sub.data) : sub.data;
      console.log(`- ID: ${sub.id}, Name: ${obj.name}, Code: ${obj.code}`);
    });
  } catch (error) {
    console.error("Failed:", error);
  } finally {
    await connection.end();
  }
}

main().catch(console.error);
