import * as admin from 'firebase-admin';

admin.initializeApp();

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
