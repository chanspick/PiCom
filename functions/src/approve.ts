import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();

export const approveSellRequest = onRequest(
  { region: "asia-northeast3", cors: ["https://kream-132e4.web.app"] },
  async (req, res): Promise<void> => {
    // CORS
    res.set('Access-Control-Allow-Origin', 'https://kream-132e4.web.app');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.set('Vary', 'Origin');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // 1️⃣ Auth
    const idToken = req.headers.authorization?.split("Bearer ")[1];
    if (!idToken) {
      res.status(403).send({ error: "Unauthorized" });
      return;
    }
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      if (decoded.admin !== true) {
        res.status(403).send({ error: "Forbidden: Not an admin" });
        return;
      }
    } catch {
      res.status(403).send({ error: "Unauthorized: Invalid token" });
      return;
    }

    // 2️⃣ Input
    const { requestId, finalPrice, finalConditionScore } = req.body || {};
    if (
      typeof requestId !== "string" || !requestId ||
      typeof finalPrice !== "number" || !Number.isFinite(finalPrice) || finalPrice <= 0 ||
      typeof finalConditionScore !== "number" || !Number.isFinite(finalConditionScore) || finalConditionScore < 0
    ) {
      res.status(400).send({ error: "Missing/invalid fields: requestId, finalPrice (>0), finalConditionScore (>=0)" });
      return;
    }

    const requestRef = db.collection("sell_requests").doc(requestId);

    try {
      const snap = await requestRef.get();
      if (!snap.exists) {
        res.status(404).send({ error: `Sell request ${requestId} not found.` });
        return;
      }

      const r = snap.data()!;
      logger.info(`sell_request keys: ${Object.keys(r).join(',')}`);

      // 3️⃣ 정규화
      const srPartId    = typeof r.partId === "string" ? r.partId : null;
      const srBrand     = typeof r.brand === "string" ? r.brand : null;
      const srModelName = typeof r.modelName === "string"
        ? r.modelName
        : (typeof r.partModelName === "string" ? r.partModelName : null);
      const srCategory  = typeof r.category === "string"
        ? r.category
        : (typeof r.partCategory === "string" ? r.partCategory : null);

      if (!srPartId && !(srModelName && (srBrand || srCategory))) {
        res.status(400).send({ error: "Insufficient identifiers (need partId or (modelName + brand/category))." });
        return;
      }

      // 4️⃣ Part 조회 (undefined 절대 금지)
      let partDoc: FirebaseFirestore.DocumentSnapshot | null = null;

      if (srPartId) {
        const byId = await db.collection("parts").doc(srPartId).get();
        if (byId.exists) partDoc = byId;
      }

      if (!partDoc && srBrand && srModelName) {
        const qs = await db.collection("parts")
          .where("brand", "==", srBrand)
          .where("modelName", "==", srModelName)
          .limit(1)
          .get();
        if (!qs.empty) partDoc = qs.docs[0];
      }

      // parts 문서엔 modelName 대신 model이 있음
      if (!partDoc && srBrand && srModelName) {
        const qs = await db.collection("parts")
          .where("brand", "==", srBrand)
          .where("model", "==", srModelName)
          .limit(1)
          .get();
        if (!qs.empty) partDoc = qs.docs[0];
      }

      if (!partDoc && srCategory && srModelName) {
        const qs = await db.collection("parts")
          .where("category", "==", srCategory)
          .where("modelName", "==", srModelName)
          .limit(1)
          .get();
        if (!qs.empty) partDoc = qs.docs[0];
      }

      if (!partDoc && srCategory && srModelName) {
        const qs = await db.collection("parts")
          .where("category", "==", srCategory)
          .where("model", "==", srModelName)
          .limit(1)
          .get();
        if (!qs.empty) partDoc = qs.docs[0];
      }

      if (!partDoc) {
        res.status(400).send({
          error: `Part not found (partId:${srPartId || 'N/A'}, brand:${srBrand || 'N/A'}, modelName:${srModelName || 'N/A'}, category:${srCategory || 'N/A'})`
        });
        return;
      }

      // 5️⃣ Listing 생성
      const partData = partDoc.data()!;
      const partId = partDoc.id;
      const resolvedBrand = (partData.brand ?? srBrand) || "";
      const resolvedModel = (srModelName ?? partData.modelName ?? partData.model) || "";

      const newListingRef = db.collection("listings").doc();
      const newListingId = newListingRef.id;

      await newListingRef.set({
        listingId: newListingId,
        partId,
        conditionScore: finalConditionScore,
        price: finalPrice,
        status: "available",
        sellerId: r.sellerId,
        buyerId: null,
        brand: resolvedBrand,
        modelName: resolvedModel,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        soldAt: null,
        imageUrls: Array.isArray(r.imageUrls) ? r.imageUrls : [],
      });

      await requestRef.update({
        listingId: newListingId,
        status: "processed",
        finalPrice,
        finalConditionScore,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Listing ${newListingId} created successfully.`);
      res.status(200).send({ success: true, listingId: newListingId });
      return;

    } catch (error) {
      logger.error(`Error processing approveSellRequest for ${requestId}:`, error);
      res.status(500).send({ error: "Internal server error" });
      return;
    }
  }
);
