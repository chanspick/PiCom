import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

export const addToCart = onCall({ region: "asia-northeast3" }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { productId, quantity } = request.data;
  if (!productId || typeof productId !== "string" || !quantity || typeof quantity !== "number" || quantity <= 0) {
    throw new HttpsError("invalid-argument", "Invalid productId or quantity.");
  }

  const productRef = db.collection("parts").doc(productId);
  const productDoc = await productRef.get();

  if (!productDoc.exists) {
    throw new HttpsError("not-found", "Product not found.");
  }
  const productData = productDoc.data();
  if (!productData) {
    throw new HttpsError("not-found", "Product data is invalid.");
  }

  const cartItemRef = db.collection("carts").doc(userId).collection("items").doc(productId);
  const cartItemDoc = await cartItemRef.get();

  if (cartItemDoc.exists) {
    throw new HttpsError("already-exists", "This item is already in your cart.");
  } else {
    await cartItemRef.set({
      productId: productId,
      productName: productData.modelName,
      price: productData.price,
      quantity: 1,
      imageUrl: productData.imageUrl || "",
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return { success: true, message: "Item added to cart successfully." };
});

export const updateCartItemQuantity = onCall({ region: "asia-northeast3" }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { productId, newQuantity } = request.data;
  if (!productId || typeof productId !== "string" || newQuantity == null || typeof newQuantity !== "number") {
    throw new HttpsError("invalid-argument", "Invalid arguments.");
  }

  const cartItemRef = db.collection("carts").doc(userId).collection("items").doc(productId);

  if (newQuantity <= 0) {
    await cartItemRef.delete();
    return { success: true, message: "Item removed from cart." };
  } else {
    await cartItemRef.update({ quantity: 1 });
    return { success: true, message: "Quantity updated." };
  }
});

export const removeFromCart = onCall({ region: "asia-northeast3" }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { productId } = request.data;
  if (!productId || typeof productId !== "string") {
    throw new HttpsError("invalid-argument", "Invalid productId.");
  }

  await db.collection("carts").doc(userId).collection("items").doc(productId).delete();
  return { success: true, message: "Item removed from cart." };
});
