import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Firebase Admin SDK 초기화
admin.initializeApp();
const db = admin.firestore();

/**
 * 'bids' 컬렉션에 새로운 문서가 생성될 때마다 실행되어 데이터 유효성을 검사합니다.
 * 유효하지 않은 데이터는 삭제하여 데이터베이스 무결성을 보장합니다.
 */
export const validateBid = functions.region("asia-northeast3") // 서울 리전
  .firestore.document("bids/{bidId}")
  .onCreate(async (snapshot, context) => {
    const bidData = snapshot.data();
    const bidId = snapshot.id;
    const userId = context.auth?.uid;

    functions.logger.info(`Validating new bid ${bidId} from user ${userId}`, {
      data: bidData,
    });

    // --- 1. 기본 데이터 구조 및 인증 확인 ---
    if (!userId) {
      functions.logger.error("Error: Bid created without user authentication.");
      return snapshot.ref.delete();
    }

    const { productId, bidAmount } = bidData;

    if (typeof productId !== "string" || !productId) {
      functions.logger.error("Error: productId is missing or not a string.");
      return snapshot.ref.delete();
    }

    if (typeof bidAmount !== "number" || bidAmount <= 0) {
      functions.logger.error("Error: bidAmount must be a positive number.");
      return snapshot.ref.delete();
    }

    // --- 2. 참조 무결성 확인 ---
    // productId가 'products' 컬렉션에 실제로 존재하는지 확인합니다.
    try {
      const productDoc = await db.collection("products").doc(productId).get();
      if (!productDoc.exists) {
        functions.logger.error(`Error: Product with ID ${productId} does not exist.`);
        return snapshot.ref.delete();
      }
    } catch (error) {
      functions.logger.error(`Error checking product existence for bid ${bidId}`, error);
      // 데이터베이스 조회 중 오류 발생 시, 일단 삭제하여 불일치 가능성을 차단합니다.
      return snapshot.ref.delete();
    }
    
    // --- 3. 데이터 일관성 유지 ---
    // 생성된 bid 문서에 userId와 생성 시간을 기록하여 데이터의 완전성을 높입니다.
    functions.logger.info(`Bid ${bidId} is valid. Enriching data.`);
    return snapshot.ref.update({
        userId: userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// 향후 모델별 가격 통계 집계 등의 백엔드 로직을 이곳에 추가할 수 있습니다.
