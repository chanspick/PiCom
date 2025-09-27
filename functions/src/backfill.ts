import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import algoliasearch from "algoliasearch";

const db = admin.firestore();

export const backfillPartsToAlgolia = onCall({region: "asia-northeast3"}, async (request) => {
  // Initialize clients inside the function
  const APP_ID = process.env.ALGOLIA_APP_ID;
  const ADMIN_KEY = process.env.ALGOLIA_API_KEY;
  const INDEX_NAME = process.env.ALGOLIA_INDEX_NAME;

  if (!APP_ID || !ADMIN_KEY || !INDEX_NAME) {
    logger.error("Algolia environment variables are not set.");
    throw new HttpsError("internal", "Algolia environment variables are not configured on the server.");
  }

  const client = algoliasearch(APP_ID, ADMIN_KEY);
  const index = client.initIndex(INDEX_NAME);

  try {
    logger.info("Starting backfill of 'parts' collection to Algolia.");

    const partsSnapshot = await db.collection("parts").get();

    if (partsSnapshot.empty) {
      logger.info("No documents found in 'parts' collection. Nothing to backfill.");
      return {message: "No parts found to backfill."};
    }

    const algoliaRecords = partsSnapshot.docs.map((doc) => {
      return {
        objectID: doc.id,
        ...doc.data(),
      };
    });

    logger.info(`Found ${algoliaRecords.length} documents to index.`);

    const {objectIDs} = await index.saveObjects(algoliaRecords);

    const successMsg = `Successfully indexed ${objectIDs.length} documents in Algolia.`;
    logger.info(successMsg);
    return {message: successMsg};
  } catch (error) {
    logger.error("Error during Algolia backfill:", error);
    if (error instanceof Error) {
      throw new HttpsError("internal", error.message);
    }
    throw new HttpsError("internal", "An unknown error occurred during backfill.");
  }
});
