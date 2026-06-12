/**
 * 기존 users 컬렉션의 평문 비밀번호(passwd)를 SHA-256 해시로 변환한다.
 * 앱의 lib/utils/password.dart 와 동일한 방식: sha256(utf8(passwd.trim())) 의 hex 문자열.
 * --------------------------------------------------
 * 실행 방법 (functions 폴더에서):
 *   - seed 때와 동일하게 인증 후:  node migrate_passwords.js
 *     (functions/serviceAccountKey.json 또는 gcloud ADC)
 *
 * 이미 해시(64자리 hex)인 값은 건드리지 않으므로 여러 번 돌려도 안전합니다.
 */

const admin = require("firebase-admin");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "moaproject-1b718";
const keyPath = path.join(__dirname, "serviceAccountKey.json");

if (fs.existsSync(keyPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
    projectId: PROJECT_ID,
  });
} else {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
  });
}

const db = admin.firestore();

const sha256Hex = (raw) =>
  crypto.createHash("sha256").update(String(raw).trim(), "utf8").digest("hex");

const isHashed = (v) => typeof v === "string" && /^[a-f0-9]{64}$/.test(v);

async function migrate() {
  const snap = await db.collection("users").get();
  let updated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const pw = doc.data().passwd;

    if (typeof pw !== "string" || pw.length === 0) {
      console.log(`  - ${doc.id}: passwd 없음 → 건너뜀`);
      skipped++;
      continue;
    }
    if (isHashed(pw)) {
      console.log(`  - ${doc.id}: 이미 해시 → 건너뜀`);
      skipped++;
      continue;
    }

    await doc.ref.update({ passwd: sha256Hex(pw) });
    console.log(`  · ${doc.id}: 평문 → 해시 변환 완료`);
    updated++;
  }

  console.log(`\n✅ 변환 ${updated}건, 건너뜀 ${skipped}건.`);
}

migrate()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("❌ 마이그레이션 실패:", e);
    process.exit(1);
  });
