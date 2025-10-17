// search.ts

import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import algoliasearch, { SearchClient } from "algoliasearch";
import { logger } from "firebase-functions/v2";

const algoliaAppId = defineString("ALGOLIA_APP_ID");
const algoliaApiKey = defineString("ALGOLIA_API_KEY");
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

    const index = indexName.value();
    logger.info(`🔍 Searching in index: "${index}" with keyword: "${keyword}"`);

    try {
      // ✅ Algolia v5: initIndex 방식 사용
      const searchIndex = client.initIndex(index);
      const result = await searchIndex.search(keyword, {
        hitsPerPage: 50,
      });

      const hits = result.hits || [];
      logger.info(`✅ Found ${hits.length} results`);
      return hits;
    } catch (error: any) {
      logger.error("❌ Algolia search error:", error);
      throw new HttpsError(
        "internal",
        `Error performing search with Algolia: ${error.message}`
      );
    }
  }
);
