import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

const db = admin.firestore();

/**
 * [HTTPS Callable] Handles the purchase of a listing.
 * This function ensures atomicity and enforces business logic for a sale.
 */
export const buyListing = functions.https.onCall(async (data, context) => {
  // 1. 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { listingId } = data;
  const buyerId = context.auth.uid;

  // 2. 데이터 유효성 검사
  if (!listingId || typeof listingId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid 'listingId'."
    );
  }

  const listingRef = db.collection("listings").doc(listingId);

  try {
    await db.runTransaction(async (transaction) => {
      const listingDoc = await transaction.get(listingRef);

      if (!listingDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Listing not found.");
      }

      const listingData = listingDoc.data();

      if (listingData?.status !== "available") {
        throw new functions.https.HttpsError("failed-precondition", "Listing is not available for purchase.");
      }

      if (listingData?.sellerId === buyerId) {
        throw new functions.https.HttpsError("failed-precondition", "Cannot buy your own listing.");
      }

      // 3. Listing 상태 업데이트
      transaction.update(listingRef, {
        status: "sold",
        buyerId: buyerId,
        soldAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // TODO: Add logic for payment processing, notifications, etc.
      logger.info(`Listing ${listingId} sold to ${buyerId}.`);
    });

    return { success: true, message: `Listing ${listingId} purchased successfully.` };
  } catch (error: any) {
    if (error.code) {
      throw error; // Re-throw HttpsError
    } else {
      logger.error(`Error buying listing ${listingId}: ${error}`);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to complete purchase.",
        error
      );
    }
  }
});
