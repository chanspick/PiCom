import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = admin.firestore();

export const addToCart = onCall({ region: "asia-northeast3" }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { listingId } = request.data;
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
    throw new HttpsError("not-found", "Listing data is invalid.");
  }

  // Check if listing is available
  if (listingData.status !== "available") {
    throw new HttpsError("failed-precondition", "Listing is not available for purchase.");
  }

  // Prevent seller from adding their own listing to cart
  if (listingData.sellerId === userId) {
    throw new HttpsError("failed-precondition", "Cannot add your own listing to cart.");
  }

  const cartItemRef = db.collection("carts").doc(userId).collection("items").doc(listingId);
  const cartItemDoc = await cartItemRef.get();

  if (cartItemDoc.exists) {
    throw new HttpsError("already-exists", "This item is already in your cart.");
  } else {
    await cartItemRef.set({
      listingId: listingId,
      partId: listingData.partId, // Keep partId for reference
      brand: listingData.brand,
      modelName: listingData.modelName,
      price: listingData.price,
      conditionScore: listingData.conditionScore,
      quantity: 1, // Quantity for a listing is always 1
      imageUrl: listingData.imageUrls && listingData.imageUrls.length > 0 ? listingData.imageUrls[0] : "", // Use first image URL
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

  const { listingId, newQuantity } = request.data;
  if (!listingId || typeof listingId !== "string" || newQuantity == null || typeof newQuantity !== "number") {
    throw new HttpsError("invalid-argument", "Invalid arguments.");
  }

  const cartItemRef = db.collection("carts").doc(userId).collection("items").doc(listingId);

  if (newQuantity <= 0) {
    await cartItemRef.delete();
    return { success: true, message: "Item removed from cart." };
  } else if (newQuantity !== 1) {
    throw new HttpsError("invalid-argument", "Listing quantity can only be 1.");
  } else {
    // If newQuantity is 1, no update is strictly needed as it's already 1
    return { success: true, message: "Quantity remains 1." };
  }
});

export const removeFromCart = onCall({ region: "asia-northeast3" }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { listingId } = request.data;
  if (!listingId || typeof listingId !== "string") {
    throw new HttpsError("invalid-argument", "Invalid listingId.");
  }

  await db.collection("carts").doc(userId).collection("items").doc(listingId).delete();
  return { success: true, message: "Item removed from cart." };
});
