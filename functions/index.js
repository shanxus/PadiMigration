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

  //
  const beenSharedID = context.params.uid;
  console.log("user who had been shared: ", beenSharedID);

  // const eventID = snapshot.val();
  // console.log("eventID: ", eventID);

  var payload = {
    notification: {
      title: 'Hello',
      body: 'It\'s Padi!'
    }
  };

  // var options = {
  //   priority: 'high',
  //   timeToLive: 60 * 60 * 24
  // };

  const registrationToken = "fHn6wiH37Ec:APA91bGbrPpurnAQa2H1H-WDEk1wfoPL9YaZqF0fOXfGSmpRbZlhm927Oh2_URb_OAFNSFWm3_7QW_SBwVtLLdMX0GwBmvX3A1I-pf0qndbdCovUdUx9e6NtUQ3zIzIICpE3c3ZRooh1";

  return admin.messaging().sendToDevice(registrationToken, payload);
  /*
  .then(function(response) {
    // See the MessagingDevicesResponse reference documentation for
    // the contents of response.
    console.log('Successfully sent message:', response);
  })
  .catch(function(error) {
    console.log('Error sending message:', error);
  });
  */
})
