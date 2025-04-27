// delete_documents.js

const admin = require('firebase-admin');

// 🚀 Initialize Firebase
const serviceAccount = require('./serviceAccountKey.json'); // Adjust path if needed

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 🚀 Function to delete all documents from a collection
async function deleteAllDocuments(collectionName) {
  console.log(`🗑️ Starting deletion of all documents in "${collectionName}" collection...`);

  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();

  if (snapshot.empty) {
    console.log('⚡ No documents found to delete.');
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log('✅ All documents deleted successfully!');
}

// 🚀 Run the deletion
const collectionToDelete = 'medicines'; // Change this to your collection name

deleteAllDocuments(collectionToDelete)
  .catch((error) => {
    console.error('❌ Error deleting documents:', error);
  });