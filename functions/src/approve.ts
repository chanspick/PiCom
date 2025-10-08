import * as admin from "firebase-admin";
import {onRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";

const db = admin.firestore();

/**
 * [V2 HTTP onRequest] Approves a sell request and creates a listing.
 */
export const approveSellRequest = onRequest(
  {region: "asia-northeast3", cors: true},
  async (req, res) => {
    // 1. Auth check: Ensure user is an admin
    const idToken = req.headers.authorization?.split("Bearer ")[1];
    if (!idToken) {
      res.status(403).send({error: "Unauthorized"});
      return;
    }
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      if (decodedToken.admin !== true) {
        res.status(403).send({error: "Forbidden: Not an admin"});
        return;
      }
    } catch (e) {
      res.status(403).send({error: "Unauthorized: Invalid token"});
      return;
    }

    // 2. Input validation
    const {requestId, finalPrice, finalConditionScore} = req.body;
    if (!requestId || !finalPrice || !finalConditionScore) {
      res.status(400).send({error: "Missing required fields: requestId, finalPrice, or finalConditionScore"});
      return;
    }

    const requestRef = db.collection("sell_requests").doc(requestId);

    try {
      // 3. Core Logic (moved from onSellRequestApproved)
      const sellRequestDoc = await requestRef.get();
      if (!sellRequestDoc.exists) {
        res.status(404).send({error: `Sell request ${requestId} not found.`});
        return;
      }
      const sellRequestData = sellRequestDoc.data()!;

      // Find corresponding part
      const partQuerySnapshot = await db.collection("parts")
        .where("category", "==", sellRequestData.partCategory)
        .where("modelName", "==", sellRequestData.partModelName)
        .limit(1)
        .get();

      if (partQuerySnapshot.empty) {
        const errorMsg = `Part not found for category ${sellRequestData.partCategory} and model ${sellRequestData.partModelName}`;
        logger.error(errorMsg);
        res.status(400).send({error: errorMsg});
        return;
      }
      const partData = partQuerySnapshot.docs[0].data();
      const partId = partData.partId;
      const brand = partData.brand;

      // Create new listing
      const newListingRef = db.collection("listings").doc();
      const newListingId = newListingRef.id;
      const listingData = {
        listingId: newListingId,
        partId: partId,
        conditionScore: finalConditionScore,
        price: finalPrice,
        status: "available",
        sellerId: sellRequestData.sellerId,
        buyerId: null,
        brand: brand,
        modelName: sellRequestData.partModelName,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        soldAt: null,
        imageUrls: sellRequestData.imageUrls,
      };
      await newListingRef.set(listingData);

      // 4. Update original request to processed
      await requestRef.update({
        listingId: newListingId,
        status: "processed", // Directly set to processed
        finalPrice: finalPrice,
        finalConditionScore: finalConditionScore,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Listing ${newListingId} created and request ${requestId} processed.`);
      res.status(200).send({success: true, listingId: newListingId});

    } catch (error) {
      logger.error(`Error processing approveSellRequest for ${requestId}:`, error);
      res.status(500).send({error: "Internal server error"});
    }
  }
);
