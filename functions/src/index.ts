import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
  FirestoreEvent,
  Change,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
import { onRequest, Request } from "firebase-functions/v2/https";
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

// ==================== 기존 Functions (변경 없음) ====================

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

export const onOrderStatusUpdate = onDocumentUpdated(
  {
    document: "orders/{orderId}",
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

    if (beforeData.status === afterData.status) {
      logger.info("Status not changed. No notification needed.");
      return;
    }

    const userId = afterData.buyerId;
    if (!userId) {
      logger.error(`Order ${change.after.id} has no buyerId.`);
      return;
    }

    const orderId = change.after.id;
    const newStatus = afterData.status;

    let notificationPayload: { title: string; body: string } | null = null;
    switch (newStatus) {
      case "awaitingSellerShipment":
        notificationPayload = {
          title: "결제가 완료되었습니다 ✅",
          body: `주문(${orderId.substring(
            0,
            6
          )}...)이(가) 정상적으로 처리되었습니다. 판매자의 상품 발송을 기다려주세요.`,
        };
        break;
      case "allItemsArrived":
        notificationPayload = {
          title: "상품이 센터에 도착했습니다 📦",
          body: "주문하신 모든 상품이 저희 검수 센터에 도착하여 곧 검수가 시작됩니다.",
        };
        break;
      case "shippedToBuyer":
        notificationPayload = {
          title: "상품이 발송되었습니다 🚚",
          body: `주문(${orderId.substring(
            0,
            6
          )}...) 상품의 검수/조립이 완료되어 고객님께 발송되었습니다.`,
        };
        break;
      case "cancelled":
        notificationPayload = {
          title: "주문이 취소되었습니다 ❌",
          body: `주문(${orderId.substring(
            0,
            6
          )}...)이(가) 취소되었습니다. 자세한 내용은 주문 내역을 확인해주세요.`,
        };
        break;
    }

    if (notificationPayload) {
      await db
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .add({
          ...notificationPayload,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          type: "orderUpdate",
          linkTo: `/orders/${orderId}`,
        });
      logger.info(
        `Notification created for user ${userId} for order ${orderId}`
      );
    }
  },
);

export const onNewQnaComment = onDocumentCreated(
  {
    document: "posts/{postId}/comments/{commentId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return;
    }

    const commentData = snapshot.data();
    const postId = event.params.postId;
    const commentAuthorId = commentData.userId;
    const adminUids = ["Xfzi3IEX5LXA13wbyJYxjftmJ9p2", "y1C8XaVM1EZkt2zjMHsykQFYlRM2"];
    if (!adminUids.includes(commentAuthorId)) {
      logger.info(`Comment by a non-admin user (${commentAuthorId}). No notification sent.`);
      return;
    }

    const postRef = db.collection("posts").doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists) {
      logger.error(`Post ${postId} not found.`);
      return;
    }

    const postAuthorId = postDoc.data()?.authorId;
    if (!postAuthorId) {
      logger.error(`Post ${postId} has no authorId.`);
      return;
    }

    if (postAuthorId === commentAuthorId) {
      logger.info("Admin commented on their own post. No notification sent.");
      return;
    }

    const notificationPayload = {
      title: "문의하신 QnA에 답변이 등록되었습니다. 💬",
      body: `"${postDoc.data()?.title}" 게시물에 관리자의 답변이 달렸습니다.`,
      type: "qnaReply",
      linkTo: `/posts/${postId}`,
    };

    await db
      .collection("users")
      .doc(postAuthorId)
      .collection("notifications")
      .add({
        ...notificationPayload,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
    logger.info(`Notification sent to ${postAuthorId} for new comment on post ${postId}.`);
    return;
  },
);

export const sendMarketingNotification = onRequest(
  { region: "asia-northeast3", cors: true },
  async (req: Request, res): Promise<void> => {
    const idToken = req.headers.authorization?.split("Bearer ")[1];
    if (!idToken) {
      res.status(403).send({ error: "Unauthorized" });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      const adminUids = ["Xfzi3IEX5LXA13wbyJYxjftmJ9p2", "y1C8XaVM1EZktzjMHsykQFYlRM2"];
      if (decoded.admin !== true && !adminUids.includes(decoded.uid)) {
        res.status(403).send({ error: "Forbidden: Not an admin" });
        return;
      }
    } catch {
      res.status(403).send({ error: "Unauthorized: Invalid token" });
      return;
    }

    const { title, body, linkTo, imageUrl } = req.body;
    if (!title || !body) {
      res.status(400).send({ error: "Missing required fields: title, body" });
      return;
    }

    try {
      const usersSnapshot = await db.collection("users").get();
      if (usersSnapshot.empty) {
        res.status(200).send({ success: true, message: "No users to notify." });
        return;
      }

      const batch = db.batch();
      usersSnapshot.forEach((userDoc) => {
        const userId = userDoc.id;
        const notificationRef = db
          .collection("users")
          .doc(userId)
          .collection("notifications")
          .doc();
        batch.set(notificationRef, {
          title,
          body,
          linkTo: linkTo || "/",
          imageUrl: imageUrl || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          type: "event",
        });
      });
      await batch.commit();
      logger.info(`Marketing notification sent to ${usersSnapshot.size} users.`);
      res.status(200).send({ success: true, message: `Notification sent to ${usersSnapshot.size} users.` });
    } catch (error) {
      logger.error("Error sending marketing notifications:", error);
      res.status(500).send({ error: "Internal server error" });
    }
  },
);

// ==================== ✅ 새로 추가: Listing Sold 시 통계 업데이트 ====================

export const onListingSold = onDocumentUpdated(
  {
    document: "listings/{listingId}",
    region: "asia-northeast3",
  },
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const change = event.data;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();

    // available -> sold 변경 감지
    if (before.status === "available" && after.status === "sold") {
      const basePartId = after.basePartId;

      if (!basePartId) {
        logger.warn(`Listing ${event.params.listingId} has no basePartId`);
        return;
      }

      try {
        await db.runTransaction(async (transaction) => {
          const basePartRef = db.collection("base_parts").doc(basePartId);

          // 현재 available 상태인 Listing들 조회 (sold된 것 제외)
          const availableListingsSnap = await transaction.get(
            db
              .collection("listings")
              .where("basePartId", "==", basePartId)
              .where("status", "==", "available")
          );

          // 남은 매물 가격들
          const remainingPrices = availableListingsSnap.docs.map(
            (doc) => doc.data().price as number
          );

          let lowestPrice: number;
          let averagePrice: number;
          let listingCount: number;

          if (remainingPrices.length === 0) {
            // 매물이 모두 sold된 경우
            lowestPrice = 0;
            averagePrice = 0;
            listingCount = 0;
          } else {
            // 통계 계산
            lowestPrice = Math.min(...remainingPrices);
            averagePrice =
              remainingPrices.reduce((sum, price) => sum + price, 0) /
              remainingPrices.length;
            listingCount = remainingPrices.length;
          }

          // BasePart 업데이트
          transaction.update(basePartRef, {
            lowestPrice: lowestPrice,
            averagePrice: Math.round(averagePrice),
            listingCount: listingCount,
          });

          // 가격 히스토리 업데이트 (오늘 날짜)
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          const dateKey = today.toISOString().split("T")[0];

          const historyRef = db
            .collection("base_part_prices")
            .doc(basePartId)
            .collection("daily_stats")
            .doc(dateKey);

          const historySnap = await transaction.get(historyRef);

          if (historySnap.exists) {
            transaction.update(historyRef, {
              lowestPrice: lowestPrice,
              averagePrice: Math.round(averagePrice),
              listingCount: listingCount,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(historyRef, {
              date: admin.firestore.Timestamp.fromDate(today),
              lowestPrice: lowestPrice,
              averagePrice: Math.round(averagePrice),
              listingCount: listingCount,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          logger.info(
            `✅ Updated basePartId ${basePartId} after listing sold: lowest=${lowestPrice}, avg=${averagePrice}, count=${listingCount}`
          );
        });
      } catch (error: any) {
        logger.error("onListingSold error:", error);
      }
    }
  }
);

// ==================== 기존 V1 Style Exports ====================

import { createPart } from "./parts";
import { buyListing } from "./listings";
import { onPartUpdatedDenormalizeListings } from "./parts_denormalization";
import { onListingCreatedFraudCheck } from "./fraud_detection";
import { addToCart, removeFromCart } from "./cart";
import { searchProducts } from "./search";
import { setAdmin } from "./admin";
import { approveSellRequest } from "./approve";
import { setupPartsData } from "./setup_parts_data";

export {
  createPart,
  buyListing,
  onPartUpdatedDenormalizeListings,
  onListingCreatedFraudCheck,
  addToCart,
  removeFromCart,
  searchProducts,
  setAdmin,
  approveSellRequest,
  setupPartsData,
};
