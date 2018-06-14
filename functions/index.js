// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');
// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
 response.send("Hello from Firebase!");
});

exports.sharedEvent = functions.database.instance('padi-79987').ref('sharedEvents/{uid}/{eventKey}').onCreate((snapshot, context) => {
  console.log("This is Padi for onCreate 2.");

  /* get shared user ID */
  // const sharedUserID = context.auth.uid;
  // console.log("sharedUserID: ", sharedUserID);

  /* get beenShared user ID */
  const beenSharedID = context.params.uid;
  console.log("user who had been shared: ", beenSharedID);

  const beenSharedUserTokenPromise = admin.database().ref().child('User').child(beenSharedID).child('token').once('value');

  return Promise.all([beenSharedUserTokenPromise]).then(result => {
    const beenSharedUserToken = result[0].val();
    console.log("notification token: ", beenSharedUserToken);

    /* send notification */
    var payload = {
      notification: {
        title: 'New Padi Event.',
        body: 'You got an new Padi event shared with you!'
      }
    };

    return admin.messaging().sendToDevice(beenSharedUserToken, payload);
  })

  // const eventID = snapshot.val();
  // console.log("eventID: ", eventID);
})
