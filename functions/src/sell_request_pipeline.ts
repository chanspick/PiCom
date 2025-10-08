import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();

// V2 Style: onNewSellRequest
export const onNewSellRequest = onDocumentCreated({ document: "sell_requests/{requestId}", region: "asia-northeast3" }, async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("No data associated with the event for onNewSellRequest");
    return;
  }
  const sellRequestData = snapshot.data();
  const requestId = event.params.requestId;

  logger.info(`New Sell Request created: ${requestId}`);
  logger.info("Sell Request Data:", sellRequestData);

  const calculatedConditionScore = Math.floor(Math.random() * 50) + 50;
  const suggestedPrice = Math.floor(sellRequestData.requestedPrice * (calculatedConditionScore / 100));

  logger.info(`Calculated Condition Score: ${calculatedConditionScore}`);
  logger.info(`Suggested Price: ${suggestedPrice}`);

  await db.collection("sellRequests").doc(requestId).update({
    calculatedConditionScore: calculatedConditionScore,
    suggestedPrice: suggestedPrice,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Sell Request ${requestId} updated with calculated scores.`);
});

// V2 Style: onSellRequestApproved
export const onSellRequestApproved = onDocumentUpdated({ document: "sell_requests/{requestId}", region: "asia-northeast3" }, async (event) => {
  const change = event.data;
  if (!change) {
    logger.error("No data associated with the event for onSellRequestApproved");
    return;
  }

  const beforeData = change.before.data();
  const afterData = change.after.data();
  const requestId = event.params.requestId;

  if (beforeData.status === "pending" && afterData.status === "approved") {
    logger.info(`Sell Request ${requestId} status changed to APPROVED.`);

    const finalPrice = afterData.finalPrice ?? afterData.suggestedPrice ?? afterData.requestedPrice;
    const finalConditionScore = afterData.finalConditionScore ?? afterData.calculatedConditionScore;

    if (!finalConditionScore) {
      logger.error(`Error: No finalConditionScore or calculatedConditionScore for approved request ${requestId}`);
      return;
    }

    const partQuerySnapshot = await db.collection("parts")
        .where("category", "==", afterData.partCategory)
        .where("modelName", "==", afterData.partModelName)
        .limit(1)
        .get();

    if (partQuerySnapshot.empty) {
      logger.error(`Error: Part not found for category ${afterData.partCategory} and model ${afterData.partModelName} for request ${requestId}`);
      return;
    }

    const partData = partQuerySnapshot.docs[0].data();
    const partId = partData.partId;
    const brand = partData.brand;

    const newListingRef = db.collection("listings").doc();
    const newListingId = newListingRef.id;

    const listingData = {
      listingId: newListingId,
      partId: partId,
      conditionScore: finalConditionScore,
      price: finalPrice,
      status: "available",
      sellerId: afterData.sellerId,
      buyerId: null,
      brand: brand,
      modelName: afterData.partModelName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      soldAt: null,
      imageUrls: afterData.imageUrls,
    };

    await newListingRef.set(listingData);

    await change.after.ref.update({
      listingId: newListingId,
      status: "processed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Listing ${newListingId} created from Sell Request ${requestId}.`);
  } else if (beforeData.status === "pending" && afterData.status === "rejected") {
    logger.info(`Sell Request ${requestId} status changed to REJECTED.`);
    await change.after.ref.update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});