import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
  FirestoreEvent,
  Change,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
import {defineString} from "firebase-functions/params";
import {logger} from "firebase-functions/v2";
import algoliasearch, {SearchClient} from "algoliasearch";

// Firebase Admin SDK 초기화
admin.initializeApp();
const db = admin.firestore();

// V2 방식으로 환경 변수 정의
const algoliaAppId = defineString("ALGOLIA_APP_ID");
const algoliaApiKey = defineString("ALGOLIA_API_KEY");
const indexName = defineString("ALGOLIA_INDEX_NAME", {default: "parts"});

// Algolia 클라이언트 지연 초기화
let _algoliaClient: SearchClient | null = null;

const getAlgoliaClient = () => {
  const appId = algoliaAppId.value();
  const apiKey = algoliaApiKey.value();

  if (_algoliaClient) {
    return _algoliaClient;
  }

  if (appId && apiKey) {
    _algoliaClient = algoliasearch(appId, apiKey);
    return _algoliaClient;
  }

  logger.error("Algolia App ID or API Key is not configured.");
  return null;
};


export const validateBid = onDocumentCreated(
  {
    document: "bids/{bidId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return;
    }
    const bidData = snapshot.data();
    const bidId = snapshot.id;
    const userId = bidData.userId;
    if (!userId) {
      logger.error(`Bid ${bidId} has no userId. Deleting.`);
      await snapshot.ref.delete();
      return;
    }
    logger.info(`Validating new bid ${bidId} from user ${userId}`);
    const {productId, bidAmount} = bidData;
    if (typeof productId !== "string" || !productId) {
      logger.error("Error: productId is missing or not a string.");
      await snapshot.ref.delete();
      return;
    }
    if (typeof bidAmount !== "number" || bidAmount <= 0) {
      logger.error("Error: bidAmount must be a positive number.");
      await snapshot.ref.delete();
      return;
    }
    try {
      const productDoc = await db.collection("products").doc(productId).get();
      if (!productDoc.exists) {
        logger.error(`Product with ID ${productId} not found.`);
        await snapshot.ref.delete();
        return;
      }
      const productData = productDoc.data();
      if (!productData || productData.status !== "active") {
        logger.error(`Product ${productId} is not active.`);
        await snapshot.ref.delete();
        return;
      }
    } catch (error) {
      logger.error(`Error checking product for bid ${bidId}`, error);
      await snapshot.ref.delete();
      return;
    }
    logger.info(`Bid ${bidId} is valid. Enriching data.`);
    try {
      await snapshot.ref.update({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "active",
        validated: true,
      });
    } catch (error) {
      logger.error(`Error updating bid ${bidId}`, error);
    }
  },
);

export const onPartCreated = onDocumentCreated(
  {
    document: "parts/{partId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return;
    }
    try {
      const client = getAlgoliaClient();
      if (!client) {
        logger.error("Could not initialize Algolia client.");
        return;
      }
      const index = client.initIndex(indexName.value());
      const data = {
        ...snapshot.data(),
        objectID: snapshot.id,
      };
      await index.saveObjects([data]);
      logger.info(`Part ${snapshot.id} indexed in Algolia successfully`);
      await snapshot.ref.update({
        algoliaIndexed: true,
        algoliaIndexedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error(`Error indexing part ${snapshot.id} to Algolia`, error);
      await snapshot.ref.update({
        algoliaIndexed: false,
        algoliaError: errorMessage,
      }).catch((updateError) => {
        logger.error("Error updating Algolia status", updateError);
      });
      throw error;
    }
  },
);

export const onPartUpdated = onDocumentUpdated(
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
    const searchableFields = ["category", "brand", "modelName"];
    const hasSearchableChanges = searchableFields.some(
      (field) => JSON.stringify(beforeData[field]) !== JSON.stringify(afterData[field]),
    );
    if (!hasSearchableChanges) {
      logger.info(`Part ${partId} updated but no indexing needed`);
      return;
    }
    try {
      const client = getAlgoliaClient();
      if (!client) {
        logger.error("Could not initialize Algolia client.");
        return;
      }
      const index = client.initIndex(indexName.value());
      const data = {
        ...afterData,
        objectID: partId,
      };
      await index.saveObjects([data]);
      logger.info(`Part ${partId} updated in Algolia successfully`);
      await change.after.ref.update({
        algoliaIndexed: true,
        algoliaIndexedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error(`Error updating part ${partId} in Algolia`, error);
      await change.after.ref.update({
        algoliaIndexed: false,
        algoliaError: errorMessage,
      }).catch((updateError) => {
        logger.error("Error updating Algolia status", updateError);
      });
      throw error;
    }
  },
);

export const onPartDeleted = onDocumentDeleted(
  {
    document: "parts/{partId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    const partId = event.params.partId;
    if (!partId) {
      logger.error("No partId in event params");
      return;
    }
    try {
      const client = getAlgoliaClient();
      if (!client) {
        logger.error("Could not initialize Algolia client.");
        return;
      }
      const index = client.initIndex(indexName.value());
      await index.deleteObject(partId);
      logger.info(`Part ${partId} deleted from Algolia successfully`);
    } catch (error) {
      logger.error(`Error deleting part ${partId} from Algolia`, error);
      throw error;
    }
  },
);

export const onUserCreated = onDocumentCreated(
  {
    document: "users/{userId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return;
    }
    const userId = snapshot.id;
    try {
      await snapshot.ref.update({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        profileCompleted: false,
        bidCount: 0,
        wonBids: 0,
        totalSpent: 0,
        preferences: {
          notifications: true,
          emailUpdates: true,
        },
      });
      logger.info(`User profile initialized for ${userId}`);
    } catch (error) {
      logger.error(`Error initializing user profile for ${userId}`, error);
    }
  },
);

export const onBidStatusChanged = onDocumentUpdated(
  {
    document: "bids/{bidId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const change = event.data;
    if (!change) return;
    const beforeStatus = change.before.data().status;
    const afterStatus = change.after.data().status;
    const bidData = change.after.data();
    if (beforeStatus !== "won" && afterStatus === "won") {
      const userId = bidData.userId;
      const bidAmount = bidData.bidAmount || 0;
      try {
        await db.collection("users").doc(userId).update({
          wonBids: admin.firestore.FieldValue.increment(1),
          totalSpent: admin.firestore.FieldValue.increment(bidAmount),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`User stats updated for winning bid ${change.after.id}`);
      } catch (error) {
        logger.error("Error updating user stats", error);
      }
    }
  },
);

export const cleanupExpiredBids = onDocumentCreated(
  {
    document: "system/cleanup-trigger",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const expiredBidsQuery = db
        .collection("bids")
        .where("status", "in", ["expired", "cancelled"])
        .where("createdAt", "<", thirtyDaysAgo)
        .limit(100);
      const expiredBids = await expiredBidsQuery.get();
      if (expiredBids.empty) {
        logger.info("No expired bids to clean up");
        return;
      }
      const batch = db.batch();
      expiredBids.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      logger.info(`Cleaned up ${expiredBids.size} expired bids`);
    } catch (error) {
      logger.error("Error during cleanup of expired bids", error);
    }
  },
);

// V1 style function exports
import { createPart } from "./parts";
import { buyListing } from "./listings";
import { onPartUpdatedDenormalizeListings } from "./parts_denormalization";
import { onListingCreatedFraudCheck } from "./fraud_detection";
import { addToCart, updateCartItemQuantity, removeFromCart } from "./cart";
import { searchProducts } from "./search";
import { setAdmin } from "./admin";
import { approveSellRequest } from "./approve";

export {
  createPart,
  buyListing, // We can remove this later, but keeping for now to avoid deployment errors
  onPartUpdatedDenormalizeListings,
  onListingCreatedFraudCheck,
  addToCart,
  updateCartItemQuantity,
  removeFromCart,
  searchProducts,
  setAdmin,
  approveSellRequest,
};