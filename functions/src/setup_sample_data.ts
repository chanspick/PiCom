
import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

// Initialize Firebase Admin SDK
// Make sure to have your service account key file in a secure location
// and set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
// For example: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = getFirestore();

async function setupSampleData() {
  console.log("Starting to set up sample data...");

  const productsCollection = "products_new";
  const ordersCollection = "orders_new";

  // Clean up existing sample data
  console.log("Deleting existing sample data...");
  await deleteCollection(productsCollection);
  await deleteCollection(ordersCollection);
  console.log("Existing sample data deleted.");

  // --- 1. Create Individual Part Products ---
  console.log("Creating individual part products...");
  const parts = {
    "코어i7-14700KF": { brand: "인텔", price: 550000, type: "CPU" },
    "라이젠7 7800X3D": { brand: "AMD", price: 480000, type: "CPU" },
    "RTX 5080": { brand: "nVidea", price: 1100000, type: "그래픽카드" },
    "RX 7800 XT": { brand: "AMD", price: 700000, type: "그래픽카드" },
    "Z890 (인텔)": { brand: "인텔", price: 250000, type: "메인보드" },
    "B650 (AMD)": { brand: "AMD", price: 200000, type: "메인보드" },
  };

  for (const [name, data] of Object.entries(parts)) {
    await db.collection(productsCollection).add({
      name: name,
      brand: data.brand,
      price: data.price,
      likes: Math.floor(Math.random() * 100),
      parts: [data.type, name], // Tag with both category and specific name
      isBundle: false, // Flag to distinguish parts from bundles
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  console.log("Individual part products created.");

  // --- 2. Create Bundled Products ---
  console.log("Creating bundled products...");
  const bundle1Parts = ["코어i7-14700KF", "RTX 5080", "Z890 (인텔)"];
  const bundle1Price =
    parts["코어i7-14700KF"].price +
    parts["RTX 5080"].price +
    parts["Z890 (인텔)"].price;

  const bundle1 = {
    name: "인텔 하이엔드 게이밍 PC",
    brand: "PCOM 조립",
    price: bundle1Price,
    likes: Math.floor(Math.random() * 200),
    parts: bundle1Parts,
    isBundle: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const bundle1Ref = await db.collection(productsCollection).add(bundle1);
  console.log(`Created bundle: ${bundle1.name}`);

  const bundle2Parts = ["라이젠7 7800X3D", "RX 7800 XT", "B650 (AMD)"];
  const bundle2Price =
    parts["라이젠7 7800X3D"].price +
    parts["RX 7800 XT"].price +
    parts["B650 (AMD)"].price;

  const bundle2 = {
    name: "AMD 가성비 게이밍 PC",
    brand: "PCOM 조립",
    price: bundle2Price,
    likes: Math.floor(Math.random() * 300),
    parts: bundle2Parts,
    isBundle: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await db.collection(productsCollection).add(bundle2);
  console.log(`Created bundle: ${bundle2.name}`);

  // --- 3. Create Sample Orders for the first bundle ---
  console.log("Creating sample orders...");
  for (const partName of bundle1Parts) {
    const partPrice = parts[partName as keyof typeof parts].price;
    // Create 5-10 historical orders for each part
    for (let i = 0; i < Math.floor(Math.random() * 6) + 5; i++) {
      const randomPrice = partPrice * (0.95 + Math.random() * 0.1); // -5% to +5% variation
      const randomDate = new Date();
      randomDate.setDate(randomDate.getDate() - Math.floor(Math.random() * 30)); // Within last 30 days

      await db.collection(ordersCollection).add({
        productId: bundle1Ref.id,
        productName: bundle1.name,
        part: partName,
        price: Math.round(randomPrice / 100) * 100, // Round to nearest 100
        createdAt: admin.firestore.Timestamp.fromDate(randomDate),
      });
    }
  }
  console.log("Sample orders created.");
  console.log("Sample data setup complete!");
}

async function deleteCollection(collectionPath: string) {
  const collectionRef = db.collection(collectionPath);
  const snapshot = await collectionRef.limit(500).get();

  if (snapshot.size === 0) {
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  // Recurse on the same function to delete more documents.
  await deleteCollection(collectionPath);
}

setupSampleData().catch((error) => {
  console.error("Error setting up sample data:", error);
  process.exit(1);
});

