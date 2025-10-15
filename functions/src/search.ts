import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import algoliasearch, { SearchClient } from "algoliasearch";
import { logger } from "firebase-functions/v2";

// Algolia 접속 정보 (Firebase 프로젝트 환경 변수에 설정해야 함)
const algoliaAppId = defineString("ALGOLIA_APP_ID");
const algoliaApiKey = defineString("ALGOLIA_API_KEY");

// === 수정된 부분 ===
// 검색할 Algolia 인덱스의 기본값을 "parts"에서 "base_parts"로 변경합니다.
const indexName = defineString("ALGOLIA_INDEX_NAME", { default: "base_parts" });

// Algolia 클라이언트 인스턴스를 재사용하기 위한 변수
let _algoliaClient: SearchClient | null = null;

/**
 * Algolia 검색 클라이언트를 초기화하고 반환하는 함수.
 * 환경 변수가 설정되지 않은 경우 null을 반환합니다.
 */
const getAlgoliaClient = (): SearchClient | null => {
  const appId = algoliaAppId.value();
  const apiKey = algoliaApiKey.value();

  // 이미 생성된 클라이언트가 있으면 재사용
  if (_algoliaClient) {
    return _algoliaClient;
  }

  // 환경 변수에서 App ID와 API Key를 가져와 클라이언트 초기화
  if (appId && apiKey) {
    _algoliaClient = algoliasearch(appId, apiKey);
    return _algoliaClient;
  }

  // 설정값이 없는 경우 에러 로그 기록
  logger.error("Algolia App ID or API Key is not configured in Firebase environment variables.");
  return null;
};

/**
 * Algolia를 사용하여 base_parts 인덱스를 검색하는 Cloud Function.
 * 인증된 사용자만 호출할 수 있으며, 'keyword'를 인자로 받습니다.
 */
export const searchProducts = onCall({ region: "asia-northeast3" }, async (request) => {
  // 1. 사용자 인증 확인
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  // 2. 'keyword' 파라미터 확인
  const keyword = request.data.keyword as string;
  if (!keyword) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with one argument \"keyword\".",
    );
  }

  try {
    // 3. Algolia 클라이언트 가져오기
    const client = getAlgoliaClient();
    if (!client) {
      // 클라이언트 초기화 실패 시 내부 서버 오류 발생
      throw new HttpsError("internal", "Algolia client not initialized. Check server logs and environment variables.");
    }

    // 4. 'base_parts' 인덱스를 대상으로 검색 실행
    const index = client.initIndex(indexName.value());
    const searchResponse = await index.search(keyword);

    // 5. 검색 결과의 hits 배열 반환
    return searchResponse.hits;
  } catch (error) {
    // 6. Algolia 검색 중 발생한 모든 에러 처리
    logger.error("Algolia search error:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while performing the search with Algolia.",
    );
  }
});