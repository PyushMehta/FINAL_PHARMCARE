const admin = require('firebase-admin');
const fs = require('fs');

console.log('🚀 Script started...');

// Initialize Firebase Admin
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase initialized successfully!');
} catch (error) {
  console.error('❌ Error initializing Firebase:', error);
  process.exit(1);
}

// Firestore reference
const db = admin.firestore();
const collectionName = 'medicines';

// Read JSON
let medicines;
try {
  const rawData = fs.readFileSync('./medicine_sample_cleaned_2024.json');
  medicines = JSON.parse(rawData);
  console.log(`✅ Loaded ${medicines.length} medicines.`);
} catch (error) {
  console.error('❌ Error reading medicines JSON:', error);
  process.exit(1);
}

// Delete and Upload
async function deleteCollection(collectionRef, batchSize) {
  const query = collectionRef.limit(batchSize);
  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(db, query, resolve) {
  const snapshot = await query.get();
  const batchSize = snapshot.size;

  if (batchSize === 0) {
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}

async function uploadData() {
  console.log('🗑️ Deleting old data...');
  try {
    const collectionRef = db.collection(collectionName);
    await deleteCollection(collectionRef, 500);
    console.log('✅ Old data deleted.');
  } catch (error) {
    console.error('❌ Error deleting old data:', error);
    process.exit(1);
  }

  console.log('⬆️ Uploading new medicines...');
  try {
    const batch = db.batch();
    medicines.forEach(medicine => {
      const docRef = db.collection(collectionName).doc(); // Auto-ID
      batch.set(docRef, medicine);
    });
    await batch.commit();
    console.log('🎯 New medicines uploaded successfully!');
  } catch (error) {
    console.error('❌ Error uploading new data:', error);
    process.exit(1);
  }
}

uploadData().catch(error => {
  console.error('❌ UploadData function failed:', error);
  process.exit(1);
});