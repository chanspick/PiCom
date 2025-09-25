import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

const db = admin.firestore();

// Define PartCategory enum for validation
enum PartCategory { gpu = "gpu", cpu = "cpu", ssd = "ssd", mainboard = "mainboard" }

/**
 * [HTTPS Callable] Creates a new part document in Firestore.
 * This function is called from the client to add new part metadata.
 * It performs validation and ensures data integrity.
 */
export const createPart = functions.https.onCall(async (data, context) => {
  // 1. 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // 2. 데이터 유효성 검사
  const { category, brand, modelName } = data;

  if (!category || !brand || !modelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields: category, brand, modelName."
    );
  }

  if (typeof category !== "string" || typeof brand !== "string" || typeof modelName !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Fields must be strings."
    );
  }

  // Enum 값 유효성 검사
  if (!(Object.values(PartCategory).includes(category as PartCategory))) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid category: ${category}. Must be one of ${Object.values(PartCategory).join(', ')}.`
    );
  }

  // 3. partId 생성 (Firestore의 auto-ID 사용)
  const partRef = db.collection("parts").doc();
  const partId = partRef.id;

  const newPartData = {
    partId: partId,
    category: category,
    brand: brand,
    modelName: modelName,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    await partRef.set(newPartData);
    logger.info(`Part ${partId} created successfully by user ${context.auth.uid}.`);
    return { partId: partId, message: "Part created successfully." };
  } catch (error) {
    logger.error(`Error creating part: ${error}`);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to create part.",
      error
    );
  }
});
