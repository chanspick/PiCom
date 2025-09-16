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
const indexName = defineString("ALGOLIA_INDEX_NAME", {default: "products"});

// Algolia 클라이언트 지연 초기화
let _algoliaClient: SearchClient | null = null;

const getAlgoliaClient = () => {
  if (!_algoliaClient) {
    // Ensure environment variables are loaded
    if (algoliaAppId.value() && algoliaApiKey.value()) {
      _algoliaClient = algoliasearch(algoliaAppId.value(), algoliaApiKey.value());
    } else {
      logger.error("Algolia App ID or API Key is not configured.");
    }
  }
  return _algoliaClient;
};


/**
 * [V2] 'bids' 컬렉션에 새 문서가 생성될 때 데이터 유효성을 검사합니다.
 */
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

    // 사용자 ID 확인
    const userId = bidData.userId;
    if (!userId) {
      logger.error(`Bid ${bidId} has no userId. Deleting.`);
      await snapshot.ref.delete();
      return;
    }

    logger.info(`Validating new bid ${bidId} from user ${userId}`);

    const {productId, bidAmount} = bidData;

    // productId 유효성 검사
    if (typeof productId !== "string" || !productId) {
      logger.error("Error: productId is missing or not a string.");
      await snapshot.ref.delete();
      return;
    }

    // bidAmount 유효성 검사
    if (typeof bidAmount !== "number" || bidAmount <= 0) {
      logger.error("Error: bidAmount must be a positive number.");
      await snapshot.ref.delete();
      return;
    }

    // 참조 무결성 확인
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

    // 데이터 일관성 유지
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

/**
 * [V2] Firestore에 새 상품이 생성되면 Algolia에 인덱싱합니다.
 */
export const onProductCreated = onDocumentCreated(
  {
    document: "products/{productId}",
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

      logger.info(`Product ${snapshot.id} indexed in Algolia successfully`);

      await snapshot.ref.update({
        algoliaIndexed: true,
        algoliaIndexedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      const errorMessage = error instanceof Error ?
        error.message :
        String(error);

      logger.error(
        `Error indexing product ${snapshot.id} to Algolia`,
        error,
      );

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

/**
 * [V2] Firestore 상품이 업데이트되면 Algolia 인덱스를 업데이트합니다.
 */
export const onProductUpdated = onDocumentUpdated(
  {
    document: "products/{productId}",
    region: "asia-northeast3",
  },
  async (
    event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>,
  ) => {
    const change = event.data;
    if (!change) {
      logger.error("No data associated with the event");
      return;
    }

    const beforeData = change.before.data();
    const afterData = change.after.data();
    const productId = change.after.id;

    const searchableFields = [
      "name", "price", "description", "category",
      "brand", "status", "images",
    ];

    const hasSearchableChanges = searchableFields.some(
      (field) => JSON.stringify(beforeData[field]) !==
                 JSON.stringify(afterData[field]),
    );

    if (!hasSearchableChanges) {
      logger.info(
        `Product ${productId} updated but no indexing needed`,
      );
      return;
    }

    try {
      const client = getAlgoliaClient();
      if (!client) {
        logger.error("Could not initialize Algolia client.");
        return;
      }
      const index = client.initIndex(indexName.value());

      if (afterData.status === "deleted" ||
          afterData.status === "inactive") {
        await index.deleteObject(productId);
        logger.info(`Product ${productId} removed from Algolia index`);
        return;
      }

      const data = {
        ...afterData,
        objectID: productId,
      };

      await index.saveObjects([data]);

      logger.info(`Product ${productId} updated in Algolia successfully`);

      await change.after.ref.update({
        algoliaIndexed: true,
        algoliaIndexedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      const errorMessage = error instanceof Error ?
        error.message :
        String(error);

      logger.error(
        `Error updating product ${productId} in Algolia`,
        error,
      );

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

/**
 * [V2] Firestore 상품이 삭제되면 Algolia 인덱스에서 삭제합니다.
 */
export const onProductDeleted = onDocumentDeleted(
  {
    document: "products/{productId}",
    region: "asia-northeast3",
  },
  async (
    event: FirestoreEvent<QueryDocumentSnapshot | undefined>,
  ) => {
    const productId = event.params.productId;
    if (!productId) {
      logger.error("No productId in event params");
      return;
    }

    try {
      const client = getAlgoliaClient();
      if (!client) {
        logger.error("Could not initialize Algolia client.");
        return;
      }
      const index = client.initIndex(indexName.value());
      
      await index.deleteObject(productId);

      logger.info(`Product ${productId} deleted from Algolia successfully`);

      const bidsQuery = db
        .collection("bids")
        .where("productId", "==", productId)
        .where("status", "==", "active");

      const activeBids = await bidsQuery.get();

      if (!activeBids.empty) {
        const batch = db.batch();
        activeBids.docs.forEach((bidDoc) => {
          batch.update(bidDoc.ref, {
            status: "cancelled",
            reason: "Product deleted",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        await batch.commit();
        logger.info(
          `Cancelled ${activeBids.size} active bids for deleted product`,
        );
      }
    } catch (error) {
      logger.error(
        `Error deleting product ${productId} from Algolia`,
        error,
      );
      throw error;
    }
  },
);

/**
 * [V2] 사용자 생성 시 기본 설정 초기화
 */
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

/**
 * [V2] 입찰 상태 변경 시 사용자 통계 업데이트
 */
export const onBidStatusChanged = onDocumentUpdated(
  {
    document: "bids/{bidId}",
    region: "asia-northeast3",
  },
  async (
    event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>,
  ) => {
    const change = event.data;
    if (!change) return;

    const beforeStatus = change.before.data().status;
    const afterStatus = change.after.data().status;
    const bidData = change.after.data();

    // 입찰이 성공한 경우 사용자 통계 업데이트
    if (beforeStatus !== "won" && afterStatus === "won") {
      const userId = bidData.userId;
      const bidAmount = bidData.bidAmount || 0;

      try {
        await db.collection("users").doc(userId).update({
          wonBids: admin.firestore.FieldValue.increment(1),
          totalSpent: admin.firestore.FieldValue.increment(bidAmount),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(
          `User stats updated for winning bid ${change.after.id}`,
        );
      } catch (error) {
        logger.error("Error updating user stats", error);
      }
    }
  },
);

/**
 * [V2] 만료된 입찰 정리 (시스템 작업)
 */
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