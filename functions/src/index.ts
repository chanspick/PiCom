import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
  FirestoreEvent,
  Change,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
import { onRequest, Request } from "firebase-functions/v2/https"; // 👈 이 줄 추가
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

export const onOrderStatusUpdate = onDocumentUpdated(
  {
    document: "orders/{orderId}",
    region: "asia-northeast3", // 서울 리전
  },
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const change = event.data;
    if (!change) {
      logger.error("No data associated with the event");
      return;
    }

    // 1. 업데이트 이전/이후 데이터 가져오기
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // 2. status 필드가 변경되었는지 확인
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

    // 3. 새로운 status 값에 따라 알림 내용 결정
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
      // TODO: 다른 상태에 대한 알림 메시지도 추가할 수 있습니다.
    }

    // 4. 알림 생성 및 발송
    if (notificationPayload) {
      // 4-1. Firestore에 알림 저장
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

      // 4-2. FCM 푸시 알림 발송 (FCM 토큰 관리 로직 필요)
      // const userDoc = await db.collection("users").doc(userId).get();
      // const fcmToken = userDoc.data()?.fcmToken;
      // ... FCM 발송 로직 ...
    }
  }
);

export const onNewQnaComment = onDocumentCreated(
  {
    document: "posts/{postId}/comments/{commentId}",
    region: "asia-northeast3", // 서울 리전
  },
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined>) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event");
      return;
    }

    const commentData = snapshot.data();
    const postId = event.params.postId;

    // 1. 댓글 작성자가 관리자인지 확인합니다.
    // 참고: QnaService의 addComment 함수에서는 'userId'를 사용하고 있으므로
    //      필드명을 'userId'로 가정합니다. 다르다면 수정이 필요합니다.
    const commentAuthorId = commentData.userId;

    // TODO: 실제 관리자의 UID 목록을 여기에 정의해야 합니다.
    // Firestore 보안 규칙에 있던 isUserAdmin() 함수와 동일한 로직을 사용합니다.
    const adminUids = ["Xfzi3IEX5LXA13wbyJYxjftmJ9p2", "y1C8XaVM1EZkt2zjMHsykQFYlRM2"];

    if (!adminUids.includes(commentAuthorId)) {
      logger.info(`Comment by a non-admin user (${commentAuthorId}). No notification sent.`);
      return;
    }

    // 2. 원본 게시물 정보를 가져와 작성자 ID 확인
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

    // 3. 관리자가 자신의 글에 댓글 다는 경우는 알림을 보내지 않음
    if (postAuthorId === commentAuthorId) {
        logger.info("Admin commented on their own post. No notification sent.");
        return;
    }

    // 4. 게시물 작성자에게 알림 데이터 생성 및 발송
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

    // TODO: FCM 푸시 알림 발송 로직 (onOrderStatusUpdate 함수와 동일한 패턴)
    // const userDoc = await db.collection("users").doc(postAuthorId).get();
    // const fcmToken = userDoc.data()?.fcmToken;
    // ... FCM 발송 로직 ...

    return;
  }
);

export const sendMarketingNotification = onRequest(
  { region: "asia-northeast3", cors: true }, // CORS를 간단하게 설정
  async (req: Request, res): Promise<void> => {
    // 1. 관리자 인증 (approveSellRequest 함수와 동일한 로직)
    const idToken = req.headers.authorization?.split("Bearer ")[1];
    if (!idToken) {
      res.status(403).send({ error: "Unauthorized" });
      return;
    }
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      // TODO: 보안 규칙과 마찬가지로 실제 admin UID 목록으로 교체하는 것을 권장
      const adminUids = ["Xfzi3IEX5LXA13wbyJYxjftmJ9p2", "y1C8XaVM1EZktzjMHsykQFYlRM2"];
      if (decoded.admin !== true && !adminUids.includes(decoded.uid)) {
        res.status(403).send({ error: "Forbidden: Not an admin" });
        return;
      }
    } catch {
      res.status(403).send({ error: "Unauthorized: Invalid token" });
      return;
    }

    // 2. 입력 값 검증
    const { title, body, linkTo, imageUrl } = req.body;
    if (!title || !body) {
      res.status(400).send({ error: "Missing required fields: title, body" });
      return;
    }

    try {
      // 3. 모든 사용자에게 알림 생성
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
          .doc(); // 새 문서 참조 생성

        batch.set(notificationRef, {
          title,
          body,
          linkTo: linkTo || "/", // 링크가 없으면 기본값 설정
          imageUrl: imageUrl || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          type: "event",
        });
      });

      await batch.commit(); // 배치 쓰기로 모든 알림 문서를 한 번에 생성

      // TODO: FCM 푸시 알림 로직 추가 (선택 사항)
      // 사용자가 많을 경우, 모든 유저의 토큰을 가져와 한번에 보내는 로직(sendMulticast)이 효율적입니다.

      logger.info(`Marketing notification sent to ${usersSnapshot.size} users.`);
      res.status(200).send({ success: true, message: `Notification sent to ${usersSnapshot.size} users.` });

    } catch (error) {
      logger.error("Error sending marketing notifications:", error);
      res.status(500).send({ error: "Internal server error" });
    }
  }
);
// V1 style function exports
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
  buyListing, // We can remove this later, but keeping for now to avoid deployment errors
  onPartUpdatedDenormalizeListings,
  onListingCreatedFraudCheck,
  addToCart,
  removeFromCart,
  searchProducts,
  setAdmin,
  approveSellRequest,
  setupPartsData,


};