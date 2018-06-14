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

/* This is a Firebase Function used to notifiy users about shared events. */
exports.sharedEvent = functions.database.instance('padi-79987').ref('sharedEvents/{uid}/{eventKey}').onCreate((snapshot, context) => {
  console.log("This is Padi for onCreate 2.");

  /* get shared user ID. */
  const sharedUserID = context.auth.uid;

  /* get promise of shared user name. */
  const sharedUserNamePromise = admin.database().ref().child('User').child(sharedUserID).child('name').once('value');

  /* get beenShared user ID. */
  const beenSharedID = context.params.uid;

  /* get promise beenShared user FCM token. */
  const beenSharedUserTokenPromise = admin.database().ref().child('User').child(beenSharedID).child('token').once('value');

  /* get event ID. */
  const eventID = snapshot.val();
  /* get promise of event name. */
  const eventNamePromise = admin.database().ref().child('exampleEventData').child(sharedUserID).child(eventID).child('name').once('value');

  /* wait for promise. */
  return Promise.all([beenSharedUserTokenPromise, sharedUserNamePromise, eventNamePromise]).then(result => {
    const sharedUserName = result[1].val();
    console.log("sharedUserName: ", sharedUserName);

    const sharedEventName = result[2].val();
    console.log("sharedEventName: ", sharedEventName);

    const beenSharedUserToken = result[0].val();
    console.log("notification token: ", beenSharedUserToken);

    var payload = {
      notification: {
        title: '新的分款活動.',
        body: sharedUserName + ' 與您分享了一筆分款活動: ' + sharedEventName + "! "
      }
    };

    /* send notification */
    return admin.messaging().sendToDevice(beenSharedUserToken, payload);
  })
})
