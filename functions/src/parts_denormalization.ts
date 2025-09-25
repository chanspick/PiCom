import * as admin from "firebase-admin";
import {
  onDocumentUpdated,
  FirestoreEvent,
  Change,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();

/**
 * [V2] onPartUpdatedDenormalizeListings
 * Firestore `parts` 문서가 업데이트될 때 관련 `listings` 문서의 비정규화된 필드를 동기화합니다.
 * `Part`의 `brand` 또는 `modelName`이 변경되면, 해당 `partId`를 참조하는 모든 `listings` 문서의
 * `brand`와 `modelName` 필드를 업데이트합니다.
 */
export const onPartUpdatedDenormalizeListings = onDocumentUpdated(
  {
    document: "parts/{partId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const change = event.data;
    if (!change) {
      logger.error("No data associated with the event");
      return;
    }

    const beforeData = change.before.data();
    const afterData = change.after.data();
    const partId = change.after.id;

    // `brand` 또는 `modelName`이 변경되었는지 확인
    const brandChanged = beforeData?.brand !== afterData?.brand;
    const modelNameChanged = beforeData?.modelName !== afterData?.modelName;

    if (!brandChanged && !modelNameChanged) {
      logger.info(`Part ${partId} updated, but brand and modelName did not change. No denormalization needed.`);
      return;
    }

    logger.info(`Part ${partId} brand or modelName changed. Denormalizing related listings.`);

    try {
      // 해당 partId를 참조하는 모든 listings 문서 쿼리
      const listingsSnapshot = await db.collection("listings")
        .where("partId", "==", partId)
        .get();

      if (listingsSnapshot.empty) {
        logger.info(`No listings found for part ${partId}.`);
        return;
      }

      const batch = db.batch();
      listingsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          brand: afterData?.brand,
          modelName: afterData?.modelName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      logger.info(`Successfully denormalized ${listingsSnapshot.size} listings for part ${partId}.`);
    } catch (error) {
      logger.error(`Error denormalizing listings for part ${partId}:`, error);
    }
  },
);
