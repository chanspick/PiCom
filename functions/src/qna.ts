
import { HttpsError, onCall, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Firestore 인스턴스
const db = admin.firestore();

/**
 * QnA 게시물에 답글(댓글)을 추가하는 Callable Function.
 * 관리자만 호출할 수 있습니다.
 */
export const addQnaReply = onCall({ region: "asia-northeast3" }, async (request: CallableRequest) => {
    // 1. 인증 확인: 로그인한 사용자인지 확인합니다.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "이 작업을 수행하려면 로그인이 필요합니다."
      );
    }

    // 2. 관리자 권한 확인: 이메일로 관리자인지 확인합니다.
    if (request.auth.token.email !== "wlsrb00g@gmail.com") {
      throw new HttpsError(
        "permission-denied",
        "답글을 작성할 권한이 없습니다. 관리자만 가능합니다."
      );
    }

    // 3. 데이터 유효성 검사
    const { postId, content } = request.data;
    if (!postId || typeof postId !== "string" || postId.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "postId가 유효하지 않습니다."
      );
    }
    if (!content || typeof content !== "string" || content.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "답글 내용이 비어있습니다."
      );
    }

    const postRef = db.collection("posts").doc(postId);
    const commentCollectionRef = postRef.collection("comments");

    try {
      // 4. 답글 데이터 생성
      await commentCollectionRef.add({
        authorId: request.auth.uid, // 답글 작성자는 현재 관리자
        authorName: request.auth.token.name || "관리자", // 토큰에 이름이 있으면 사용
        content: content,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        likedBy: [],
      });

      // (선택) 답글이 달리면 게시물의 상태를 '답변완료'로 변경
      await postRef.update({ status: "answered" });

      return { success: true, message: "답글이 성공적으로 등록되었습니다." };
    } catch (error) {
      console.error("답글 추가 중 오류 발생:", error);
      throw new HttpsError(
        "internal",
        "답글을 추가하는 중에 오류가 발생했습니다."
      );
    }
});
