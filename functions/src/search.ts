import { HttpsError, onCall } from "firebase-functions/v2/https";
import {defineString} from "firebase-functions/params";
import algoliasearch, {SearchClient} from "algoliasearch";
import {logger} from "firebase-functions/v2";

const algoliaAppId = defineString("ALGOLIA_APP_ID");
const algoliaApiKey = defineString("ALGOLIA_API_KEY");
const indexName = defineString("ALGOLIA_INDEX_NAME", {default: "parts"});

let _algoliaClient: SearchClient | null = null;

const getAlgoliaClient = () => {
  const appId = algoliaAppId.value();
  const apiKey = algoliaApiKey.value();

  if (_algoliaClient) {
    return _algoliaClient;
  }

  if (appId && apiKey) {
    _algoliaClient = algoliasearch(appId, apiKey);
    return _algoliaClient;
  }

  logger.error("Algolia App ID or API Key is not configured.");
  return null;
};

export const searchProducts = onCall({ region: "asia-northeast3" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  const keyword = request.data.keyword as string;
  if (!keyword) {
    throw new HttpsError(
        "invalid-argument",
        "The function must be called with one argument \"keyword\".",
    );
  }

  try {
    const client = getAlgoliaClient();
    if (!client) {
      throw new HttpsError("internal", "Algolia client not initialized.");
    }
    const index = client.initIndex(indexName.value());
    const searchResponse = await index.search(keyword);
    return searchResponse.hits;
  } catch (error) {
    console.error("Algolia search error:", error);
    throw new HttpsError(
        "internal",
        "Error performing search with Algolia.",
    );
  }
});