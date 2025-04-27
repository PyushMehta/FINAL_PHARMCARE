console.log('🔥 Script started');
const fs = require('fs');

// Read the file
let medicines;
try {
  medicines = JSON.parse(fs.readFileSync('medicine_sample_cleaned_2024.json'));
} catch (error) {
  console.error('❌ Failed to read JSON file:', error.message);
  process.exit(1); // Stop the script
}

// Add the "sell" field
medicines = medicines.map(medicine => {
  const price = medicine.price ?? 0;
  return {
    ...medicine,
    sell: parseFloat((price * 1.10).toFixed(2)) // 10% increase
  };
});

// Save it back
fs.writeFileSync('medicine_sample_cleaned_2024_with_sell.json', JSON.stringify(medicines, null, 2));

console.log('✅ Done! "sell" prices added.');
