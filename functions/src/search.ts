// search.ts
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import algoliasearch, { SearchClient } from "algoliasearch";
import { logger } from "firebase-functions/v2";

const algoliaAppId = defineString("ALGOLIA_APP_ID");
const algoliaApiKey = defineString("ALGOLIA_API_KEY");
// === 수정: default 값을 명확하게 지정 ===
const indexName = defineString("ALGOLIA_INDEX_NAME", { default: "base_parts" });

let _algoliaClient: SearchClient | null = null;

const getAlgoliaClient = (): SearchClient | null => {
  const appId = algoliaAppId.value();
  const apiKey = algoliaApiKey.value();

  if (_algoliaClient) {
    return _algoliaClient;
  }

  if (appId && apiKey) {
    logger.info(`✅ Initializing Algolia with App ID: ${appId}`);
    _algoliaClient = algoliasearch(appId, apiKey);
    return _algoliaClient;
  }

  logger.error("❌ Algolia credentials not configured");
  return null;
};

export const searchProducts = onCall(
  { region: "asia-northeast3" },
  async (request) => {
    const { keyword } = request.data;

    if (!keyword || keyword.trim().length === 0) {
      return [];
    }

    const client = getAlgoliaClient();
    if (!client) {
      throw new HttpsError(
        "internal",
        "Algolia client not initialized. Check environment variables."
      );
    }

    // === 수정: indexName.value()로 명확하게 값 가져오기 ===
    const index = indexName.value();
    logger.info(`🔍 Searching in index: "${index}" with keyword: "${keyword}"`);

    try {
      const results = await client.searchSingleIndex({
        indexName: index,
        searchParams: {
          query: keyword,
          hitsPerPage: 50,
        },
      });

      logger.info(`✅ Found ${results.hits.length} results`);
      return results.hits;

    } catch (error: any) {
      logger.error("❌ Algolia search error:", error);
      throw new HttpsError(
        "internal",
        `Error performing search with Algolia: ${error.message}`
      );
    }
  }
);
