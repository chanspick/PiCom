import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Firebase Admin SDK 초기화. Cloud Functions 환경에서는 자동으로 구성됩니다.
admin.initializeApp();
const db = admin.firestore();

/**
 * 새로운 판매 입찰(ask)이 생성되었을 때 거래를 시도하는 함수
 */
export const onAskCreated = functions.region("asia-northeast3") // 서울 리전
  .firestore.document("asks/{askId}")
  .onCreate(async (snap) => {
    const ask = snap.data(); // 새로 생성된 판매 입찰 정보
    const productId = ask.productId;

    // 1. 이 상품을 사려는 가장 높은 가격의 유효한 구매 입찰(bid)을 찾습니다.
    const bidsQuery = db.collection("bids")
      .where("productId", "==", productId)
      .where("status", "==", "active")
      .orderBy("price", "desc") // 가장 높은 가격 순으로
      .orderBy("createdAt", "asc") // 같은 가격이면 먼저 입찰한 순으로
      .limit(1);

    const bidsSnapshot = await bidsQuery.get();

    // 2. 만약 판매 희망가보다 높거나 같은 구매 입찰이 있다면 거래를 체결합니다.
    if (!bidsSnapshot.empty) {
      const highestBidDoc = bidsSnapshot.docs[0];
      const highestBid = highestBidDoc.data();

      if (ask.price <= highestBid.price) {
        // 거래 체결!
        const tradePrice = highestBid.price; // 기존 구매 입찰자에게 유리한 가격으로 체결

        await executeTrade(
          productId,
          tradePrice,
          ask.userId, // seller
          highestBid.userId, // buyer
          snap.ref, // askDocRef
          highestBidDoc.ref // bidDocRef
        );
      }
    }
    // 3. 거래가 체결되지 않았더라도, 상품의 최저 판매 희망가(lowestAsk)를 업데이트합니다.
    await updateLowestAsk(productId);
  });

/**
 * 새로운 구매 입찰(bid)이 생성되었을 때 거래를 시도하는 함수 (onAskCreated와 대칭)
 */
export const onBidCreated = functions.region("asia-northeast3")
  .firestore.document("bids/{bidId}")
  .onCreate(async (snap) => {
    const bid = snap.data();
    const productId = bid.productId;

    const asksQuery = db.collection("asks")
      .where("productId", "==", productId)
      .where("status", "==", "active")
      .orderBy("price", "asc") // 가장 낮은 가격 순으로
      .orderBy("createdAt", "asc")
      .limit(1);

    const asksSnapshot = await asksQuery.get();

    if (!asksSnapshot.empty) {
      const lowestAskDoc = asksSnapshot.docs[0];
      const lowestAsk = lowestAskDoc.data();

      if (bid.price >= lowestAsk.price) {
        const tradePrice = lowestAsk.price; // 기존 판매 입찰자에게 유리한 가격으로 체결

        await executeTrade(
          productId,
          tradePrice,
          lowestAsk.userId, // seller
          bid.userId, // buyer
          lowestAskDoc.ref, // askDocRef
          snap.ref // bidDocRef
        );
      }
    }
    await updateHighestBid(productId);
  });

/**
 * 실제 거래를 실행하고 관련 문서들을 업데이트하는 트랜잭션 함수
 */
async function executeTrade(
  productId: string,
  price: number,
  sellerId: string,
  buyerId: string,
  askDocRef: admin.firestore.DocumentReference,
  bidDocRef: admin.firestore.DocumentReference
) {
  const productRef = db.collection("products").doc(productId);

  return db.runTransaction(async (transaction) => {
    // 1. 주문(order) 문서 생성
    const orderRef = db.collection("orders").doc();
    transaction.set(orderRef, {
      productId,
      price,
      sellerId,
      buyerId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. 사용된 입찰(ask, bid) 상태를 'filled'로 변경
    transaction.update(askDocRef, {status: "filled"});
    transaction.update(bidDocRef, {status: "filled"});

    // 3. 상품 문서 업데이트: 최근 거래가 및 거래 기록 추가
    transaction.update(productRef, {
      lastTradedPrice: price,
      priceHistory: admin.firestore.FieldValue.arrayUnion({
        date: admin.firestore.FieldValue.serverTimestamp(),
        price: price,
      }),
    });
  }).then(() => {
    // 4. 거래 체결 후, 최신 시세로 업데이트
    console.log(`Trade executed for product ${productId} at price ${price}`);
    return Promise.all([
      updateLowestAsk(productId),
      updateHighestBid(productId),
    ]);
  });
}

/**
 * 상품의 최저 판매 희망가(lowestAsk)를 업데이트하는 헬퍼 함수
 */
async function updateLowestAsk(productId: string) {
  const asksQuery = await db.collection("asks")
    .where("productId", "==", productId)
    .where("status", "==", "active")
    .orderBy("price", "asc")
    .limit(1)
    .get();

  const productRef = db.collection("products").doc(productId);
  if (asksQuery.empty) {
    return productRef.update({lowestAsk: null});
  } else {
    const newLowestAsk = asksQuery.docs[0].data().price;
    return productRef.update({lowestAsk: newLowestAsk});
  }
}

/**
 * 상품의 최고 구매 희망가(highestBid)를 업데이트하는 헬퍼 함수
 */
async function updateHighestBid(productId: string) {
  const bidsQuery = await db.collection("bids")
    .where("productId", "==", productId)
    .where("status", "==", "active")
    .orderBy("price", "desc")
    .limit(1)
    .get();

  const productRef = db.collection("products").doc(productId);
  if (bidsQuery.empty) {
    return productRef.update({highestBid: null});
  } else {
    const newHighestBid = bidsQuery.docs[0].data().price;
    return productRef.update({highestBid: newHighestBid});
  }
}
