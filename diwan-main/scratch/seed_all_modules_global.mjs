import mysql from "mysql2/promise";
import dotenv from "dotenv";
dotenv.config();

async function seedGlobalAllModules() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 3306,
  });

  console.log("🚀 Seeding global demo data for ALL modules across the platform...");
  const now = new Date().toISOString();
  const todayStr = new Date().toISOString().split("T")[0];

  const helperInsert = async (table, items) => {
    let count = 0;
    for (const item of items) {
      try {
        await conn.query(
          `INSERT INTO \`${table}\` (id, data, uid, createdAt, updatedAt)
           VALUES (?, ?, ?, ?, ?)
           ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
          [item.id, JSON.stringify(item), item.uid || "admin-uid", item.createdAt || now, item.updatedAt || now]
        );
        count++;
      } catch (e) {
        // Continue if duplicate or connection glitch
      }
    }
    console.log(`  ✓ Table '${table}': ${count} items upserted.`);
  };

  // 1. Fee Structures & Financial Categories
  await helperInsert("fee_structures", [
    { id: "FEE-001", name: "Annual Tuition Fee 2025-2026", grade: "Grade 10", amount: 2400, frequency: "Annual", category: "Tuition", status: "Active" },
    { id: "FEE-002", name: "Grade 3 Tuition & Activity Fee", grade: "Grade 3", amount: 1800, frequency: "Annual", category: "Tuition", status: "Active" },
    { id: "FEE-003", name: "Transport Fee (Muscat Area)", grade: "All Grades", amount: 450, frequency: "Termly", category: "Transport", status: "Active" },
    { id: "FEE-004", name: "Hostel & Dining Fee", grade: "All Grades", amount: 1200, frequency: "Termly", category: "Hostel", status: "Active" },
  ]);

  // 2. Invoices & Receipts
  await helperInsert("invoices", [
    { id: "INV-2026-001", studentId: "STU-DEMO0001", studentName: "Aisha Demo Al-Student", grade: "Grade 3", section: "A", title: "Term 1 Tuition Fee", amount: 600, paidAmount: 600, status: "Paid", dueDate: "2026-09-01", createdAt: now },
    { id: "INV-2026-002", studentId: "STU001", studentName: "John Doe", grade: "Grade 10", section: "A", title: "Term 1 Tuition & Lab Fee", amount: 850, paidAmount: 850, status: "Paid", dueDate: "2026-09-01", createdAt: now },
    { id: "INV-2026-003", studentId: "STD-1221", studentName: "Ishaan Abraham", grade: "Grade 2", section: "D", title: "Term 1 Tuition Fee", amount: 550, paidAmount: 0, status: "Pending", dueDate: "2026-09-30", createdAt: now },
    { id: "INV-2026-004", studentId: "STD-5842", studentName: "abish s a", grade: "Grade 1", section: "A", title: "Term 1 Tuition Fee", amount: 550, paidAmount: 550, status: "Paid", dueDate: "2026-09-01", createdAt: now },
  ]);

  await helperInsert("receipts", [
    { id: "RCPT-2026-001", invoiceId: "INV-2026-001", studentId: "STU-DEMO0001", studentName: "Aisha Demo Al-Student", amount: 600, paymentMethod: "Card", transactionRef: "TXN-998811", date: todayStr, createdAt: now },
    { id: "RCPT-2026-002", invoiceId: "INV-2026-002", studentId: "STU001", studentName: "John Doe", amount: 850, paymentMethod: "Bank Transfer", transactionRef: "TXN-998812", date: todayStr, createdAt: now },
  ]);

  // 3. Expenses & Bank Transactions
  await helperInsert("expenses", [
    { id: "EXP-001", category: "Lab Supplies", description: "Chemistry & Physics Experiment Consumables", amount: 1450, vendor: "Oman Scientific Supplies", status: "Approved", date: todayStr },
    { id: "EXP-002", category: "IT Infrastructure", description: "Fiber Internet & Server Upkeep", amount: 890, vendor: "Omantel", status: "Paid", date: todayStr },
    { id: "EXP-003", category: "Facility Maintenance", description: "AC Servicing & Air Filter Replacement", amount: 1200, vendor: "Muscat HVAC Care", status: "Approved", date: todayStr },
  ]);

  // 4. Transport Routes & Vehicles
  await helperInsert("transport_routes", [
    { id: "RT-01", name: "Route 1: Al-Khuwair & Qurum Express", busNumber: "BUS-101", driverName: "Sultan Al-Harthy", driverPhone: "+968 99112233", capacity: 35, enrolledCount: 28, status: "Active" },
    { id: "RT-02", name: "Route 2: Seeb & Mawaleh Line", busNumber: "BUS-102", driverName: "Mohammed Al-Balushi", driverPhone: "+968 99223344", capacity: 40, enrolledCount: 34, status: "Active" },
    { id: "RT-03", name: "Route 3: Azaiba & Bausher Express", busNumber: "BUS-103", driverName: "Salim Al-Kindi", driverPhone: "+968 99334455", capacity: 35, enrolledCount: 30, status: "Active" },
  ]);

  await helperInsert("transport_vehicles", [
    { id: "BUS-101", plateNumber: "98211-B", model: "Toyota Coaster 2024", capacity: 35, status: "Operational", lastService: "2026-08-15" },
    { id: "BUS-102", plateNumber: "45120-B", model: "Nissan Civil 2023", capacity: 40, status: "Operational", lastService: "2026-08-20" },
    { id: "BUS-103", plateNumber: "67231-B", model: "Mitsubishi Rosa 2024", capacity: 35, status: "Operational", lastService: "2026-08-22" },
  ]);

  // 5. Hostel Rooms & Allocations
  await helperInsert("hostel_rooms", [
    { id: "RM-101", roomNumber: "101", block: "Block A (Boys)", capacity: 2, occupied: 2, status: "Full", floor: "1st Floor" },
    { id: "RM-102", roomNumber: "102", block: "Block A (Boys)", capacity: 2, occupied: 1, status: "Available", floor: "1st Floor" },
    { id: "RM-201", roomNumber: "201", block: "Block B (Girls)", capacity: 2, occupied: 2, status: "Full", floor: "2nd Floor" },
  ]);

  await helperInsert("hostel_allocations", [
    { id: "HAL-01", roomNumber: "101", studentId: "STU001", studentName: "John Doe", block: "Block A (Boys)", allocatedDate: "2026-08-25", status: "Active" },
    { id: "HAL-02", roomNumber: "201", studentId: "STU-DEMO0001", studentName: "Aisha Demo Al-Student", block: "Block B (Girls)", allocatedDate: "2026-08-25", status: "Active" },
  ]);

  // 6. Cafeteria Mess Menu
  await helperInsert("mess_menu", [
    { id: "MM-MON", day: "Monday", mealType: "Lunch", menuItems: "Omani Shuwa Rice, Fresh Salad, Hummus, Orange Juice", category: "Regular" },
    { id: "MM-TUE", day: "Tuesday", mealType: "Lunch", menuItems: "Grilled Chicken Biryani, Raita, Lentil Soup, Fresh Fruit", category: "Regular" },
    { id: "MM-WED", day: "Wednesday", mealType: "Lunch", menuItems: "Pasta Bolognese, Garlic Bread, Ceasar Salad, Apple", category: "Regular" },
    { id: "MM-THU", day: "Thursday", mealType: "Lunch", menuItems: "Fish Sayadieh, Tahini, Garden Salad, Dates & Milk", category: "Regular" },
  ]);

  // 7. Library Catalogue & Loans
  await helperInsert("library", [
    { id: "LIB-001", title: "Fundamentals of Physics (11th Ed)", author: "Halliday & Resnick", category: "Science", isbn: "978-1118230718", availableCopies: 5, totalCopies: 8, location: "Shelf S-04" },
    { id: "LIB-002", title: "To Kill a Mockingbird", author: "Harper Lee", category: "Literature", isbn: "978-0060935467", availableCopies: 4, totalCopies: 6, location: "Shelf L-12" },
    { id: "LIB-003", title: "Clean Code: A Handbook of Agile Software Craftsmanship", author: "Robert C. Martin", category: "Computer Science", isbn: "978-0132350884", availableCopies: 3, totalCopies: 4, location: "Shelf C-02" },
    { id: "LIB-004", title: "Arabic Language & Rhetoric", author: "Dr. Al-Jabri", category: "Arabic", isbn: "978-9990102030", availableCopies: 6, totalCopies: 10, location: "Shelf A-01" },
  ]);

  // 8. Notices & Calendar Events
  await helperInsert("notices", [
    { id: "NTC-001", title: "Upcoming Parent-Teacher Meeting (PTM)", category: "Academic", content: "The Q1 Parent-Teacher conference is scheduled for September 25th. All parents are requested to book time slots.", date: todayStr, author: "School Principal" },
    { id: "NTC-002", title: "Annual Sports Day Registration Open", category: "Sports", content: "Students can register for track & field events with their PE instructors.", date: todayStr, author: "Sports Department" },
    { id: "NTC-003", title: "Mid-Term Examination Schedule Released", category: "Exams", content: "The official timetable for Mid-Term Exams has been posted under the Examinations portal.", date: todayStr, author: "Exam Controller" },
  ]);

  // 9. Behavior Incidents & Achievements
  await helperInsert("behavior_incidents", [
    { id: "BEH-001", studentId: "STU001", studentName: "John Doe", grade: "Grade 10", section: "A", type: "Positive Merit", title: "Exceptional Peer Mentoring in Robotics Lab", points: 15, date: todayStr, reportedBy: "Fatima Al-Rashid" },
    { id: "BEH-002", studentId: "STU-DEMO0001", studentName: "Aisha Demo Al-Student", grade: "Grade 3", section: "A", type: "Positive Merit", title: "Outstanding Performance in Spelling Bee", points: 20, date: todayStr, reportedBy: "Fatima Al-Rashid" },
  ]);

  await helperInsert("achievements", [
    { id: "ACH-001", studentId: "STU001", studentName: "John Doe", title: "1st Place - Oman National Youth Science Fair", category: "Science", year: "2025-2026", awardedBy: "Ministry of Education" },
    { id: "ACH-002", studentId: "STU-DEMO0001", studentName: "Aisha Demo Al-Student", title: "Gold Medalist - Regional Mathematics Olympiad", category: "Academics", year: "2025-2026", awardedBy: "Math Council" },
  ]);

  await conn.end();
  console.log("✨ Global Demo Data Seeding Completed for ALL Modules!");
}

seedGlobalAllModules().catch(console.error);
