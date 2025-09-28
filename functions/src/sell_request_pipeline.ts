import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// Cloud Function 1: onNewSellRequest
// Triggers when a new sell request is created.
// Conceptually, this is where you'd call your Python pricing model.
export const onNewSellRequest = functions.firestore
    .document("sellRequests/{requestId}")
    .onCreate(async (snapshot, context) => {
      const sellRequestData = snapshot.data();
      const requestId = context.params.requestId;

      console.log(`New Sell Request created: ${requestId}`);
      console.log("Sell Request Data:", sellRequestData);

      // --- Conceptual: Call Python Pricing Model Here ---
      // In a real scenario, you would make an HTTP request to your Python service
      // or use a Pub/Sub topic to trigger a Python Cloud Function.
      // For this implementation, we'll simulate the calculation.
      const calculatedConditionScore = Math.floor(Math.random() * 50) + 50; // Simulate 50-99
      const suggestedPrice = Math.floor(sellRequestData.requestedPrice * (calculatedConditionScore / 100));
      // --- End Conceptual ---

      console.log(`Calculated Condition Score: ${calculatedConditionScore}`);
      console.log(`Suggested Price: ${suggestedPrice}`);

      // Update the SellRequest document with the calculated values
      await db.collection("sellRequests").doc(requestId).update({
        calculatedConditionScore: calculatedConditionScore,
        suggestedPrice: suggestedPrice,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Sell Request ${requestId} updated with calculated scores.`);
    });

// Cloud Function 2: onSellRequestApproved
// Triggers when a sell request's status changes to 'approved'.
export const onSellRequestApproved = functions.firestore
    .document("sellRequests/{requestId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const requestId = context.params.requestId;

      // Only proceed if status changed from pending to approved
      if (beforeData.status === "pending" && afterData.status === "approved") {
        console.log(`Sell Request ${requestId} status changed to APPROVED.`);

        // Determine the final price and condition score to use for the Listing
        const finalPrice = afterData.finalPrice ?? afterData.suggestedPrice ?? afterData.requestedPrice;
        const finalConditionScore = afterData.finalConditionScore ?? afterData.calculatedConditionScore;

        if (!finalConditionScore) {
          console.error(`Error: No finalConditionScore or calculatedConditionScore for approved request ${requestId}`);
          return null;
        }

        // Fetch the corresponding Part data to get partId and brand
        // Assuming partCategory and partModelName are sufficient to find a unique part
        const partQuerySnapshot = await db.collection("parts")
            .where("category", "==", afterData.partCategory)
            .where("modelName", "==", afterData.partModelName)
            .limit(1)
            .get();

        if (partQuerySnapshot.empty) {
          console.error(`Error: Part not found for category ${afterData.partCategory} and model ${afterData.partModelName} for request ${requestId}`);
          // Optionally, update sell request status to indicate an error or require manual intervention
          return null;
        }

        const partData = partQuerySnapshot.docs[0].data();
        const partId = partData.partId; // Use the partId stored in the part document
        const brand = partData.brand;

        // Create a new Listing document
        const newListingRef = db.collection("listings").doc(); // Auto-generate listingId
        const newListingId = newListingRef.id;

        const listingData = {
          listingId: newListingId,
          partId: partId,
          conditionScore: finalConditionScore,
          price: finalPrice,
          status: "available", // New listings are available
          sellerId: afterData.sellerId,
          buyerId: null,
          brand: brand,
          modelName: afterData.partModelName,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          soldAt: null,
          imageUrls: afterData.imageUrls,
        };

        await newListingRef.set(listingData);

        // Update the original SellRequest document with the new listingId and final status
        await change.after.ref.update({
          listingId: newListingId, // Store the ID of the created listing
          status: "processed", // Mark sell request as processed
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Listing ${newListingId} created from Sell Request ${requestId}.`);
      } else if (beforeData.status === "pending" && afterData.status === "rejected") {
        console.log(`Sell Request ${requestId} status changed to REJECTED.`);
        // Optionally, notify the seller about the rejection
        await change.after.ref.update({
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      return null;
    });
