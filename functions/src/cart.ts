// functions/src/cart.ts
import * as admin from "firebase-admin";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * 사용자의 장바구니에 특정 리스팅을 추가합니다.
 * 재고가 1개인 상품이므로 수량은 항상 1로 고정됩니다.
 */
export const addToCart = onCall({region: "asia-northeast3"}, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const {listingId} = request.data;
  if (!listingId || typeof listingId !== "string") {
    throw new HttpsError("invalid-argument", "Invalid listingId.");
  }

  const listingRef = db.collection("listings").doc(listingId);
  const listingDoc = await listingRef.get();

  if (!listingDoc.exists) {
    throw new HttpsError("not-found", "Listing not found.");
  }
  const listingData = listingDoc.data();
  if (!listingData) {
    throw new HttpsError("internal", "Listing data is invalid.");
  }

  // 재고 상태 확인
  if (listingData.status !== "available") {
    throw new HttpsError("failed-precondition", "This listing is no longer available.");
  }

  // 자신의 상품은 담을 수 없음
  if (listingData.sellerId === userId) {
    throw new HttpsError("failed-precondition", "You cannot add your own item to the cart.");
  }

  const cartItemRef = db.collection("users").doc(userId).collection("cart").doc(listingId);
  const cartItemDoc = await cartItemRef.get();

  if (cartItemDoc.exists) {
    throw new HttpsError("already-exists", "This item is already in your cart.");
  }

  // CartItem 문서를 생성하여 Firestore에 저장
  await cartItemRef.set({
    listingId: listingId,
    partId: listingData.partId,
    brand: listingData.brand,
    modelName: listingData.modelName, // 'productName' 대신 'modelName'으로 저장
    price: listingData.price,
    imageUrl: listingData.imageUrls && listingData.imageUrls.length > 0 ? listingData.imageUrls[0] : "",
    quantity: 1, // 수량은 항상 1로 고정
    addedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {success: true, message: "Item added to cart successfully."};
});

/**
 * 사용자의 장바구니에서 특정 리스팅을 제거합니다.
 */
export const removeFromCart = onCall({region: "asia-northeast3"}, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const {listingId} = request.data;
  if (!listingId || typeof listingId !== "string") {
    throw new HttpsError("invalid-argument", "Invalid listingId.");
  }

  await db.collection("users").doc(userId).collection("cart").doc(listingId).delete();
  return {success: true, message: "Item removed from cart."};
});