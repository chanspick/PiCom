import * as admin from 'firebase-admin';

// IMPORTANT: Make sure you have your service account key file named 'key.json' 
// in the 'functions' directory.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const serviceAccount = require('../key.json');

// Get the email from command line arguments
const emailToMakeAdmin = process.argv[2];

if (!emailToMakeAdmin) {
  console.error('ERROR: Please provide an email address as an argument.');
  console.log('Usage: npm run set-admin -- <email-to-make-admin>');
  process.exit(1);
}

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();

(async () => {
  try {
    console.log(`Attempting to grant admin privileges to: ${emailToMakeAdmin}...`);
    const user = await auth.getUserByEmail(emailToMakeAdmin);
    const currentClaims = user.customClaims || {};

    if (currentClaims.admin === true) {
      console.log(`User ${emailToMakeAdmin} is already an admin.`);
      return;
    }

    await auth.setCustomUserClaims(user.uid, { ...currentClaims, admin: true });
    console.log(`✅ Success! Custom claim 'admin: true' has been set for ${emailToMakeAdmin}.`);
    console.log('Please log out and log back in on the admin page to see the changes.');

  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      console.error(`Error: User with email ${emailToMakeAdmin} not found.`);
    } else {
      console.error('An unexpected error occurred:');
      console.error(error);
    }
    process.exit(1);
  }
})();
