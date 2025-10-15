import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

const db = admin.firestore();

export const approveSellRequest = onRequest(
  { region: "asia-northeast3", cors: true },
  async (req, res): Promise<void> => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    // 1️⃣ Auth (변경 없음)
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

    // 2️⃣ Input (변경 없음)
    const { requestId, finalPrice, finalConditionScore } = req.body || {};
    if (
      !requestId || typeof requestId !== "string" ||
      !finalPrice || typeof finalPrice !== "number" || finalPrice <= 0 ||
      !finalConditionScore || typeof finalConditionScore !== "number" || finalConditionScore < 0 || finalConditionScore > 100
    ) {
      res.status(400).send({ error: "Missing/invalid fields" });
      return;
    }

    const sellRequestRef = db.collection("sell_requests").doc(requestId);

    try {
      // [추가] Firestore 트랜잭션을 사용하여 전체 로직을 감쌉니다.
      const newListingId = await db.runTransaction(async (transaction) => {
        const sellRequestSnap = await transaction.get(sellRequestRef);
        if (!sellRequestSnap.exists) {
          throw new Error(`Sell request ${requestId} not found.`);
        }

        const r = sellRequestSnap.data()!;
        if (r.status === "processed") {
          logger.info(`Request ${requestId} already processed.`);
          return r.listingId || null; // 이미 처리된 경우 기존 리스팅 ID 반환
        }

        // 3️⃣ 정규화 (기존 로직과 동일)
        const srPartId = typeof r.partId === "string" ? r.partId : null;
        const srBrand = typeof r.brand === "string" ? r.brand : null;
        const srModelName = typeof r.modelName === "string" ? r.modelName : (typeof r.partModelName === "string" ? r.partModelName : null);
        const srCategory = typeof r.category === "string" ? r.category : (typeof r.partCategory === "string" ? r.partCategory : null);
        if (!srPartId && !(srModelName && (srBrand || srCategory))) {
          throw new Error("Insufficient identifiers (need partId or (modelName + brand/category)).");
        }

        // 4️⃣ Part 조회 (기존의 안정적인 로직 그대로 사용)
        let partDoc: FirebaseFirestore.DocumentSnapshot | null = null;
        if (srPartId) {
          const byId = await transaction.get(db.collection("parts").doc(srPartId));
          if (byId.exists) partDoc = byId;
        }
        if (!partDoc && srBrand && srModelName) {
            const qs = await transaction.get(db.collection("parts").where("brand", "==", srBrand).where("modelName", "==", srModelName).limit(1));
            if (!qs.empty) partDoc = qs.docs[0];
        }
        if (!partDoc && srBrand && srModelName) {
            const qs = await transaction.get(db.collection("parts").where("brand", "==", srBrand).where("model", "==", srModelName).limit(1));
            if (!qs.empty) partDoc = qs.docs[0];
        }
        if (!partDoc && srCategory && srModelName) {
            const qs = await transaction.get(db.collection("parts").where("category", "==", srCategory).where("modelName", "==", srModelName).limit(1));
            if (!qs.empty) partDoc = qs.docs[0];
        }
        if (!partDoc && srCategory && srModelName) {
            const qs = await transaction.get(db.collection("parts").where("category", "==", srCategory).where("model", "==", srModelName).limit(1));
            if (!qs.empty) partDoc = qs.docs[0];
        }
        if (!partDoc) {
          throw new Error(`Part not found (partId:${srPartId || 'N/A'}, brand:${srBrand || 'N/A'}, modelName:${srModelName || 'N/A'})`);
        }

        const partData = partDoc.data()!;

        // [핵심 기능 추가] Part 문서에서 basePartId를 가져와 listingCount를 업데이트합니다.
        const basePartId = partData.basePartId;
        if (!basePartId) {
          throw new Error(`basePartId is missing in part document ${partDoc.id}.`);
        }
        const basePartRef = db.collection("base_parts").doc(basePartId);
        transaction.update(basePartRef, {
          listingCount: admin.firestore.FieldValue.increment(1),
        });

        // 5️⃣ Listing 생성 (기존 로직과 동일)
        const newListingRef = db.collection("listings").doc();
        transaction.set(newListingRef, {
            listingId: newListingRef.id,
            partId: partDoc.id,
            basePartId: basePartId,
            conditionScore: finalConditionScore,
            price: finalPrice,
            status: "available",
            sellerId: r.sellerId,
            buyerId: null,
            brand: (partData.brand ?? srBrand) || "",
            modelName: (srModelName ?? partData.modelName ?? partData.model) || "",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            soldAt: null,
            imageUrls: Array.isArray(r.imageUrls) ? r.imageUrls : [],
        });

        // 6️⃣ SellRequest 업데이트 (기존 로직과 동일)
        transaction.update(sellRequestRef, {
            listingId: newListingRef.id,
            status: "processed",
            finalPrice,
            finalConditionScore,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return newListingRef.id; // 성공 시 생성된 리스팅 ID를 반환
      });

      logger.info(`Listing ${newListingId} created successfully for request ${requestId}.`);
      res.status(200).send({ success: true, listingId: newListingId });

    } catch (error) {
      logger.error(`Error in transaction for approveSellRequest ${requestId}:`, error);
      const errorMessage = error instanceof Error ? error.message : "Internal server error";
      res.status(500).send({ error: errorMessage });
    }
  }
);