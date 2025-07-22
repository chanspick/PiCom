import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';

class AuthUtils {
static final AuthService _authService = AuthService();

/// Firestore 쓰기 작업 시 권한 오류 처리 및 로그인 유도
static Future<void> tryWriteWithLoginGuard(
BuildContext context,
Future<void> Function() writeAction,
) async {
return await _authService.tryWriteWithLoginGuard(context, writeAction);
}

/// 인증 상태 확인 및 로그인 유도
static bool requireAuth(BuildContext context) {
return _authService.requireAuth(context);
}

/// 익명 사용자 확인
static bool isAnonymous() {
return _authService.isAnonymous;
}

/// 로그인 상태 확인
static bool isLoggedIn() {
return _authService.isLoggedIn;
}

/// 현재 사용자 정보
static User? get currentUser => _authService.currentUser;

/// 게스트 사용자에게 로그인 권유 메시지 표시
static void showLoginPrompt(BuildContext context, String action) {
if (isAnonymous()) {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('로그인 필요'),
content: Text('$action 기능을 사용하려면 Google 계정으로 로그인해주세요.'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('나중에'),
),
ElevatedButton(
onPressed: () {
Navigator.pop(context);
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const AuthScreen(),
),
);
},
child: const Text('로그인'),
),
],
),
);
}
}

/// 사용자 권한 확인 (판매자, 구매자 등)
static Future<bool> checkUserPermission(
BuildContext context,
String requiredAction,
) async {
// 로그인 확인
if (!requireAuth(context)) {
return false;
}

// 익명 사용자는 거래 불가
if (isAnonymous()) {
showLoginPrompt(context, requiredAction);
return false;
}

return true;
}

/// 사용자 프로필 완성도 확인
static Future<bool> isProfileComplete(String uid) async {
try {
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();

if (!doc.exists) return false;

final data = doc.data()!;
return data['email']?.isNotEmpty == true &&
data['name']?.isNotEmpty == true;
} catch (e) {
return false;
}
}

/// 로그아웃 확인 다이얼로그
static void showLogoutDialog(BuildContext context) {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('로그아웃'),
content: const Text('정말 로그아웃하시겠습니까?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('취소'),
),
ElevatedButton(
onPressed: () async {
Navigator.pop(context);
await _authService.signOut();
},
child: const Text('로그아웃'),
),
],
),
);
}

/// 계정 삭제 확인 다이얼로그
static void showDeleteAccountDialog(BuildContext context) {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('계정 삭제'),
content: const Text('정말 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('취소'),
),
ElevatedButton(
onPressed: () async {
Navigator.pop(context);
try {
await _authService.deleteAccount();
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('계정이 삭제되었습니다.'),
),
);
}
} catch (e) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('계정 삭제 중 오류가 발생했습니다: $e'),
backgroundColor: Colors.red,
),
);
}
}
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
),
child: const Text('삭제'),
),
],
),
);
}
}
