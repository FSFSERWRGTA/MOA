/**
 * serviceScrapes 컬렉션 시드 스크립트
 * --------------------------------------------------
 * 실행 방법 (functions 폴더에서):
 *
 *   1) 서비스 계정 키로 인증 (권장)
 *      - Firebase 콘솔 > 프로젝트 설정 > 서비스 계정 > "새 비공개 키 생성"
 *      - 내려받은 파일을 functions/serviceAccountKey.json 으로 저장
 *      - PowerShell:  node seed_service_scrapes.js
 *
 *   2) 또는 gcloud ADC 인증
 *      - gcloud auth application-default login
 *      - PowerShell:  node seed_service_scrapes.js
 *
 * 같은 docId 로 다시 실행하면 덮어씁니다(멱등). 가격이 바뀌면 값만 고쳐 재실행하세요.
 *
 * ⚠️ serviceAccountKey.json 은 절대 깃에 커밋하지 마세요(.gitignore 에 추가 권장).
 */

const admin = require("firebase-admin");
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
  // gcloud ADC 또는 GOOGLE_APPLICATION_CREDENTIALS 환경변수 사용
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
  });
}

const db = admin.firestore();

// 날짜 스탬프(문서 ID 접미사). 필요시 수정하세요.
const STAMP = "20260610";

/**
 * 각 서비스 문서.
 *  - providerId : 서비스 식별자 (추천 프롬프트에 "서비스명"으로 들어감)
 *  - serviceType: 카테고리. 코드가 소문자로 읽음. OTT는 'ott', AI는 'ai'.
 *  - plans[]    : planName + amount 는 필수. cycle/currency/planId 권장.
 *
 * 통화: 모두 원화(KRW). AI 툴은 USD 가격을 약 1,400원/USD로 환산해 넣었습니다.
 */
const SERVICES = [
  // ===================== OTT (serviceType: 'ott', KRW) =====================
  {
    docId: `evt_netflix_${STAMP}`,
    providerId: "netflix",
    providerName: "넷플릭스",
    serviceType: "ott",
    plans: [
      { planId: "ads",      planName: "광고형 스탠다드", amount: 7000,  currency: "KRW", cycle: "month" },
      { planId: "standard", planName: "스탠다드",        amount: 13500, currency: "KRW", cycle: "month" },
      { planId: "premium",  planName: "프리미엄",        amount: 17000, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_youtube_premium_${STAMP}`,
    providerId: "youtube_premium",
    providerName: "유튜브 프리미엄",
    serviceType: "ott",
    plans: [
      { planId: "lite",    planName: "프리미엄 라이트", amount: 8500,  currency: "KRW", cycle: "month" },
      { planId: "music",   planName: "뮤직 프리미엄",   amount: 11990, currency: "KRW", cycle: "month" },
      { planId: "premium", planName: "프리미엄",        amount: 14900, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_tving_${STAMP}`,
    providerId: "tving",
    providerName: "티빙",
    serviceType: "ott",
    plans: [
      { planId: "ads",      planName: "광고형 스탠다드", amount: 5500,  currency: "KRW", cycle: "month" },
      { planId: "basic",    planName: "베이직",          amount: 9500,  currency: "KRW", cycle: "month" },
      { planId: "standard", planName: "스탠다드",        amount: 13500, currency: "KRW", cycle: "month" },
      { planId: "premium",  planName: "프리미엄",        amount: 17000, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_disneyplus_${STAMP}`,
    providerId: "disneyplus",
    providerName: "디즈니플러스",
    serviceType: "ott",
    plans: [
      { planId: "standard", planName: "스탠다드", amount: 9900,  currency: "KRW", cycle: "month" },
      { planId: "premium",  planName: "프리미엄", amount: 13900, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_watcha_${STAMP}`,
    providerId: "watcha",
    providerName: "왓챠",
    serviceType: "ott",
    plans: [
      { planId: "basic",   planName: "베이직",   amount: 7900,  currency: "KRW", cycle: "month" },
      { planId: "premium", planName: "프리미엄", amount: 12900, currency: "KRW", cycle: "month" },
    ],
  },

  // ===================== AI 툴 (serviceType: 'ai', KRW) =====================
  {
    docId: `evt_chatgpt_${STAMP}`,
    providerId: "chatgpt",
    providerName: "ChatGPT",
    serviceType: "ai",
    plans: [
      { planId: "go",   planName: "Go",   amount: 15000,  currency: "KRW", cycle: "month" },
      { planId: "plus", planName: "Plus", amount: 29000,  currency: "KRW", cycle: "month" },
      { planId: "pro",  planName: "Pro",  amount: 290000, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_claude_${STAMP}`,
    providerId: "claude",
    providerName: "Claude",
    serviceType: "ai",
    plans: [
      { planId: "pro", planName: "Pro", amount: 28000,  currency: "KRW", cycle: "month" },
      { planId: "max", planName: "Max", amount: 140000, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_gemini_${STAMP}`,
    providerId: "gemini",
    providerName: "Gemini",
    serviceType: "ai",
    plans: [
      { planId: "pro",   planName: "Google AI Pro",   amount: 28000,  currency: "KRW", cycle: "month" },
      { planId: "ultra", planName: "Google AI Ultra", amount: 350000, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_perplexity_${STAMP}`,
    providerId: "perplexity",
    providerName: "Perplexity",
    serviceType: "ai",
    plans: [
      { planId: "pro", planName: "Pro", amount: 28000,  currency: "KRW", cycle: "month" },
      { planId: "max", planName: "Max", amount: 280000, currency: "KRW", cycle: "month" },
    ],
  },
  {
    docId: `evt_grok_${STAMP}`,
    providerId: "grok",
    providerName: "Grok",
    serviceType: "ai",
    plans: [
      { planId: "supergrok", planName: "SuperGrok",       amount: 42000,  currency: "KRW", cycle: "month" },
      { planId: "heavy",     planName: "SuperGrok Heavy", amount: 420000, currency: "KRW", cycle: "month" },
    ],
  },
];

async function seed() {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  for (const svc of SERVICES) {
    const ref = db.collection("serviceScrapes").doc(svc.docId);
    batch.set(ref, {
      providerId: svc.providerId,
      providerName: svc.providerName,
      serviceType: svc.serviceType,
      description: null,
      plans: svc.plans.map((p) => ({ promo: false, ...p })),
      createdAt: now,
      fetchedAt: now,
    });
    console.log(`  · ${svc.docId} (${svc.plans.length} plans)`);
  }

  await batch.commit();
  console.log(`\n✅ serviceScrapes 에 ${SERVICES.length}개 문서를 기록했습니다.`);
}

seed()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("❌ 시드 실패:", e);
    process.exit(1);
  });
