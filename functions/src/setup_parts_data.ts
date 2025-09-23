import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

// Firebase Admin SDK 초기화
// 로컬 개발 환경에서는 'firebase login' 또는 'gcloud auth application-default login'을 통해
// 인증된 사용자 정보를 자동으로 사용합니다.
admin.initializeApp();

const db = admin.firestore();

async function migratePartsData() {
  console.log("Starting data migration...");

  // parts.txt 파일 경로 설정 (functions 폴더 기준)
  const filePath = path.join(__dirname, "../../lib/models/parts.txt");
  const fileContent = fs.readFileSync(filePath, "utf-8");
  const lines = fileContent.split("\n");

  const partsToUpload: any[] = [];
  let currentCategory = "";

  for (const line of lines) {
    const trimmedLine = line.trim();

    if (trimmedLine.startsWith("[") && trimmedLine.endsWith("]")) {
      // 카테고리 변경
      currentCategory = trimmedLine.substring(1, trimmedLine.length - 1);
    } else if (trimmedLine.length > 0 && currentCategory) {
      // 브랜드 및 제품 파싱
      const parts = trimmedLine.split(":");
      if (parts.length < 2) continue;

      const brand = parts[0].trim();
      const productNames = parts[1].split(",").map((name) => name.trim());

      for (const productName of productNames) {
        if (productName) {
          const partData = {
            category: currentCategory,
            brand: brand,
            name: productName,
            modelCode: productName.replace(/\s+/g, "-").toUpperCase(), // 모델 코드는 이름 기반으로 생성
            imageUrl: "", // 기본값
            createdAt: new Date(),
          };
          partsToUpload.push(partData);
        }
      }
    }
  }

  if (partsToUpload.length === 0) {
    console.log("No parts found to upload.");
    return;
  }

  console.log(`Found ${partsToUpload.length} parts to upload.`);

  // Firestore에 일괄 쓰기(Batch Write)
  const batch = db.batch();
  const partsCollection = db.collection("parts");

  partsToUpload.forEach((part) => {
    const docRef = partsCollection.doc(); // Firestore가 자동으로 ID 생성
    batch.set(docRef, part);
  });

  try {
    await batch.commit();
    console.log("Successfully migrated all parts data to Firestore!");
  } catch (error) {
    console.error("Error committing batch:", error);
  }
}

migratePartsData().catch((error) => {
  console.error("Migration script failed:", error);
});
