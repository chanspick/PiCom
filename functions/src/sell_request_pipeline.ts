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

  await db.collection("sell_requests").doc(requestId).update({
    calculatedConditionScore: calculatedConditionScore,
    suggestedPrice: suggestedPrice,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Sell Request ${requestId} updated with calculated scores.`);
});
