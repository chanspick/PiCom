
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const addToCart = functions.region("asia-northeast3").https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in to add items to cart.");
  }

  const { productId, quantity } = data;
  if (!productId || typeof productId !== "string" || !quantity || typeof quantity !== "number" || quantity <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid productId or quantity.");
  }

  try {
    const productRef = db.collection("parts").doc(productId);
    const productDoc = await productRef.get();

    if (!productDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Product not found.");
    }

    const productData = productDoc.data();
    if (!productData || productData.stock < quantity) {
      throw new functions.httpsa.HttpsError("out-of-range", "Not enough stock available.");
    }

    const cartItemRef = db.collection("carts").doc(userId).collection("items").doc(productId);
    const cartItemDoc = await cartItemRef.get();

    if (cartItemDoc.exists) {
      // 아이템이 이미 장바구니에 있는 경우 수량 업데이트
      const newQuantity = cartItemDoc.data()!.quantity + quantity;
      if (productData.stock < newQuantity) {
        throw new functions.https.HttpsError("out-of-range", "Not enough stock available.");
      }
      await cartItemRef.update({ quantity: newQuantity });
    } else {
      // 새 아이템 추가
      await cartItemRef.set({
        productId: productId,
        productName: productData.modelName, // part_model.dart의 modelName 필드 사용
        price: productData.price,
        quantity: quantity,
        imageUrl: productData.imageUrl || "",
        addedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true, message: "Item added to cart successfully." };
  } catch (error) {
    console.error("Error adding to cart:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "An internal error occurred.");

export const updateCartItemQuantity = functions.region("asia-northeast3").https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const { productId, newQuantity } = data;
  if (!productId || typeof productId !== "string" || !newQuantity || typeof newQuantity !== "number") {
    throw new functions.https.HttpsError("invalid-argument", "Invalid arguments.");
  }

  const cartItemRef = db.collection("carts").doc(userId).collection("items").doc(productId);

  if (newQuantity <= 0) {
    await cartItemRef.delete();
    return { success: true, message: "Item removed from cart." };
  } else {
    const productRef = db.collection("parts").doc(productId);
    const productDoc = await productRef.get();
    if (!productDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Product not found.");
    }
    const productData = productDoc.data();
    if (productData!.stock < newQuantity) {
      throw new functions.https.HttpsError("out-of-range", "Not enough stock.");
    }
    await cartItemRef.update({ quantity: newQuantity });
    return { success: true, message: "Quantity updated." };
  }
});

export const removeFromCart = functions.region("asia-northeast3").https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const { productId } = data;
  if (!productId || typeof productId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Invalid productId.");
  }

  await db.collection("carts").doc(userId).collection("items").doc(productId).delete();
  return { success: true, message: "Item removed from cart." };
});

