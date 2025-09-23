import * as functions from "firebase-functions";
/**
 * 새로운 상품이 Firestore에 생성되면 Algolia에도 추가합니다.
 */
export declare const onProductCreated: functions.CloudFunction<functions.firestore.FirestoreEvent<functions.firestore.QueryDocumentSnapshot | undefined, {
    productId: string;
}>>;
/**
 * 상품이 Firestore에서 업데이트되면 Algolia에서도 업데이트합니다.
 */
export declare const onProductUpdated: functions.CloudFunction<functions.firestore.FirestoreEvent<functions.firestore.Change<functions.firestore.QueryDocumentSnapshot> | undefined, {
    productId: string;
}>>;
/**
 * 상품이 Firestore에서 삭제되면 Algolia에서도 삭제합니다.
 */
export declare const onProductDeleted: functions.CloudFunction<functions.firestore.FirestoreEvent<functions.firestore.QueryDocumentSnapshot | undefined, {
    productId: string;
}>>;
/**
 * 클라이언트로부터 검색어를 받아 Algolia에서 상품을 검색합니다.
 * @param {string} keyword - 검색할 키워드
 * @returns {Promise<any>} Algolia 검색 결과
 */
export declare const searchProducts: functions.https.CallableFunction<any, Promise<{
    readonly objectID: string;
    readonly _highlightResult?: {} | undefined;
    readonly _snippetResult?: {} | undefined;
    readonly _rankingInfo?: import("@algolia/client-search").RankingInfo;
    readonly _distinctSeqID?: number;
}[]>, unknown>;
/**
 * 'bids' 컬렉션에 새로운 문서가 생성될 때마다 실행되어 데이터 유효성을 검사합니다.
 */
export declare const validateBid: functions.CloudFunction<functions.firestore.FirestoreEvent<functions.firestore.QueryDocumentSnapshot | undefined, {
    bidId: string;
}>>;
//# sourceMappingURL=index.d.ts.map