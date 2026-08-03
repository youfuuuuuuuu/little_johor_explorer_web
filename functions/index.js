const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteAuthAccountOnDocDelete = functions.firestore
    .document('users/{userId}')
    .onDelete(async (snap, context) => {
        const deletedUserId = context.params.userId;
        
        try {
            await admin.auth().deleteUser(deletedUserId);
            console.log(`Successfully deleted Auth account for user: ${deletedUserId}`);
        } catch (error) {
            console.error(`Failed to delete Auth account:`, error);
        }
    });