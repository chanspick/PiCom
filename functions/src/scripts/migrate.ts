
import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

// Firebase Admin SDK 초기화
admin.initializeApp();

const db = admin.firestore();

async function migrateCpuData() {
  console.log("Starting CPU data migration from JSON...");

  // all_cpus_combined.json 파일 경로 설정
  const filePath = path.join(__dirname, "../../../../lib/models/all_cpus_combined.json");

  let cpuObjects: any[];

  try {
    const fileContent = fs.readFileSync(filePath, "utf-8");
    cpuObjects = JSON.parse(fileContent);
  } catch (error) {
    console.error(`Error reading or parsing the JSON file at ${filePath}:`, error);
    return;
  }

  if (!Array.isArray(cpuObjects) || cpuObjects.length === 0) {
    console.log("No CPU data found in the JSON file. Nothing to migrate.");
    return;
  }

  const batch = db.batch();
  const partsCollection = db.collection("parts");
  let partsCounter = 0;

  for (const cpuData of cpuObjects) {
    if (cpuData && cpuData.part_id) {
      // 각 CPU 객체에 category 필드 추가
      const partDataWithCategory = {
        ...cpuData,
        category: "cpu", // PartCategory.cpu
      };

      // part_id를 문서 ID로 사용하여 데이터 저장
      const docRef = partsCollection.doc(cpuData.part_id);
      batch.set(docRef, partDataWithCategory);
      partsCounter++;
    } else {
      console.warn("Skipping an item because it is invalid or missing a part_id:", cpuData);
    }
  }

  if (partsCounter === 0) {
    console.log("No valid parts found to upload.");
    return;
  }

  console.log(`Found ${partsCounter} CPU parts to upload.`);

  try {
    await batch.commit();
    console.log("Successfully migrated all CPU data to Firestore!");
  } catch (error) {
    console.error("Error committing batch:", error);
  }
}

migrateCpuData().catch((error) => {
  console.error("Migration script failed:", error);
});
