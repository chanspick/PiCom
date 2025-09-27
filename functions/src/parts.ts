import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

// Define PartCategory enum for validation
enum PartCategory { gpu = "gpu", cpu = "cpu", ssd = "ssd", mainboard = "mainboard" }

/**
 * [V2 HTTPS Callable] Creates a new part document in Firestore.
 * This function is called from the client to add new part metadata.
 * It performs validation and ensures data integrity.
 */
export const createPart = onCall({region: "asia-northeast3"}, async (request) => {
  // 1. 인증 확인
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // 2. 데이터 유효성 검사
  const {category, brand, modelName} = request.data;

  if (!category || !brand || !modelName) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: category, brand, modelName."
    );
  }

  if (typeof category !== "string" || typeof brand !== "string" || typeof modelName !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Fields must be strings."
    );
  }

  // Enum 값 유효성 검사
  if (!(Object.values(PartCategory).includes(category as PartCategory))) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid category: ${category}. Must be one of ${Object.values(PartCategory).join(", ")}.`
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
    logger.info(`Part ${partId} created successfully by user ${request.auth.uid}.`);
    return {partId: partId, message: "Part created successfully."};
  } catch (error) {
    logger.error(`Error creating part:`, error);
    throw new HttpsError(
      "internal",
      "Failed to create part.",
      error
    );
  }
});
