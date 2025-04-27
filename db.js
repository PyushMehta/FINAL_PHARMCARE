// upload_to_firestore.js

const admin = require('firebase-admin');
const fs = require('fs');

// 🚀 Initialize Firebase
const serviceAccount = require('./serviceAccountKey.json'); // Make sure correct path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 🚀 Load JSON data
let data;
try {
  data = JSON.parse(fs.readFileSync('medicine_sample_cleaned_2024_with_sell.json')); // Change to your JSON filename
} catch (error) {
  console.error('❌ Failed to load JSON:', error.message);
  process.exit(1);
}

console.log(`✅ Loaded ${data.length} documents.`);

// 🚀 Upload to Firestore
async function uploadData() {
  const batch = db.batch();
  const collectionRef = db.collection('medicines'); // 🔥 Change collection name if needed

  data.forEach((item) => {
    const docRef = collectionRef.doc(); // Auto-generated ID
    batch.set(docRef, item);
  });

  await batch.commit();
  console.log('✅ Data uploaded to Firestore successfully!');
}

uploadData().catch((error) => {
  console.error('❌ Upload failed:', error);
});