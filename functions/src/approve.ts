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
      !requestId || typeof requestId !== "string" ||
      !finalPrice || typeof finalPrice !== "number" || finalPrice <= 0 ||
      !finalConditionScore || typeof finalConditionScore !== "number" ||
      finalConditionScore < 1 || finalConditionScore > 100
    ) {
      res.status(400).send({ error: "Invalid input" });
      return;
    }

    try {
      // 3️⃣ Transaction으로 처리
      await db.runTransaction(async (transaction) => {
        const requestRef = db.collection("sell_requests").doc(requestId);
        const requestSnap = await transaction.get(requestRef);

        if (!requestSnap.exists) {
          throw new Error("SellRequest not found");
        }

        const requestData = requestSnap.data()!;
        if (requestData.status !== "pending") {
          throw new Error(`Invalid status: ${requestData.status}`);
        }

        const sellerId = requestData.userId;
        const partId = requestData.partId;

        if (!sellerId || !partId) {
          throw new Error("Missing userId or partId in SellRequest");
        }

        // 4️⃣ Part 정보 조회 (basePartId 가져오기)
        const partRef = db.collection("parts").doc(partId);
        const partSnap = await transaction.get(partRef);
        if (!partSnap.exists) {
          throw new Error("Part not found");
        }
        const partData = partSnap.data()!;
        const basePartId = partData.basePartId;

        if (!basePartId) {
          throw new Error("basePartId not found in Part");
        }

        // ✅ 추가: BasePart 존재 여부 확인
        const basePartRef = db.collection("base_parts").doc(basePartId);
        const basePartSnap = await transaction.get(basePartRef);
        if (!basePartSnap.exists) {
          throw new Error(`BasePart ${basePartId} not found. Please create BasePart first.`);
        }

        // 5️⃣ Listing 생성
        const newListingRef = db.collection("listings").doc();
        const newListing = {
          listingId: newListingRef.id,
          basePartId: basePartId,
          partId: partId,
          brand: partData.brand || "",
          modelName: partData.modelName || "",
          conditionScore: finalConditionScore,
          price: finalPrice,
          status: "available",
          sellerId: sellerId,
          buyerId: null,
          imageUrls: requestData.imageUrls || [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          soldAt: null,
        };
        transaction.set(newListingRef, newListing);

        // 6️⃣ 가격 통계 계산 및 업데이트
        // 현재 해당 basePartId의 available Listing들 조회
        const existingListingsSnap = await transaction.get(
          db.collection("listings")
            .where("basePartId", "==", basePartId)
            .where("status", "==", "available")
        );

        // 기존 매물 가격들 + 새로 추가되는 가격
        const allPrices = existingListingsSnap.docs.map(doc => doc.data().price as number);
        allPrices.push(finalPrice);

        // 최저가, 평균가, 매물수 계산
        const lowestPrice = Math.min(...allPrices);
        const averagePrice = allPrices.reduce((sum, price) => sum + price, 0) / allPrices.length;
        const listingCount = allPrices.length;

        // BasePart 업데이트
        transaction.update(basePartRef, {
          lowestPrice: lowestPrice,
          averagePrice: Math.round(averagePrice),
          listingCount: listingCount,
        });

        // 7️⃣ 가격 히스토리 기록 (일별)
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const dateKey = today.toISOString().split('T')[0];

        const historyRef = db
          .collection("base_part_prices")
          .doc(basePartId)
          .collection("daily_stats")
          .doc(dateKey);

        const historySnap = await transaction.get(historyRef);

        if (historySnap.exists) {
          transaction.update(historyRef, {
            lowestPrice: lowestPrice,
            averagePrice: Math.round(averagePrice),
            listingCount: listingCount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(historyRef, {
            date: admin.firestore.Timestamp.fromDate(today),
            lowestPrice: lowestPrice,
            averagePrice: Math.round(averagePrice),
            listingCount: listingCount,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // 8️⃣ SellRequest 상태 업데이트
        transaction.update(requestRef, {
          status: "approved",
          reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
          finalPrice: finalPrice,
          finalConditionScore: finalConditionScore,
          listingId: newListingRef.id,
        });

        logger.info(`✅ Approved request ${requestId}, created listing ${newListingRef.id}`);
        logger.info(`📊 Updated basePartId ${basePartId}: lowest=${lowestPrice}, avg=${Math.round(averagePrice)}, count=${listingCount}`);
      });

      res.status(200).send({ success: true });
    } catch (error: any) {
      logger.error("approveSellRequest error:", error);
      res.status(500).send({ error: error.message || "Internal server error" });
    }
  }
);
