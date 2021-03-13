const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();


exports.onCreateFollower = functions.firestore.document("/followers/{userId}/userFollowers/{followerId}").onCreate(async (snapshot, context) => {
    console.log("Follower Created", snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    // Create Followed Users Post
    const followedUserPostRef = admin.firestore().collection('posts').doc(userId).collection('userPosts');

    console.log("Create lover Users Post");
    // Create Following User's Timeline
    const timelinePostsRef = admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts');

    console.log("Create lover's post for User's Timeline");

    // Get Followed User's Post
    const querySnapshot = await followedUserPostRef.get();

    // Add Each User Post to Timeline
    querySnapshot.forEach(doc => {
        if (doc.exists) {
            const postId = doc.id;
            const postData = doc.data();
            timelinePostsRef.doc(postId).set(postData);
        }
    });
    console.log("Add Each lovers Post to Timeline");
});

exports.onDeleteFollower = functions.firestore.document("/followers/{userId}/userFollowers/{followerId}").onDelete(async (snapshot, context) => {

    console.log("Follower Deleted", snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    const timelinePostsRef = admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts').where("ownerId", "==", userId);

    console.log("Got all the post of ur Arch Enemy");

    const querySnapshot = await timelinePostsRef.get();
    querySnapshot.forEach(doc => {

        if (doc.exists) {
            doc.ref.delete();
        }
    });

    console.log("Deleted All the Posts of the Arch Enemy");
});

// when a post is created add to timeline of all users

exports.onCreatePost = functions.firestore.document('/posts/{userId}/userPosts/{postId}').onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // Get All the Followers of user who made the post
    const userFollowersRef = admin.firestore.collection('followers').doc(userId).collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    // Add new Post to each followers timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;

        admin.firestore.collection('timeline').doc(followerId).collection('timelinePosts').doc(postId).set(postCreated);
    });
    console.log("Added the Posts of the Arch Enemy Later");
});

exports.onUpdatePost = functions.firestore.document('/posts/{userId}/userPosts/{postId}').onUpdate(async (change, context) => {

    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // Get All the Followers of user who made the post
    const userFollowersRef = admin.firestore.collection('followers').doc(userId).collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    // Update new Post in each followers timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;

        admin.firestore.collection('timeline').doc(followerId).collection('timelinePosts').doc(postId).get().then(doc => {

            if (doc.exists) {
                doc.ref.update(postUpdated);
            }
        });
        console.log("Updated the Posts of the Arch Enemy Later");
    });
});

// ON Delete Post
exports.onDeletePost = functions.firestore.document('/posts/{userId}/userPosts/{postId}').onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    // Get All the Followers of user who made the post
    const userFollowersRef = admin.firestore.collection('followers').doc(userId).collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    // Delete new Post in each followers timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;

        admin.firestore.collection('timeline').doc(followerId).collection('timelinePosts').doc(postId).get().then(doc => {

            if (doc.exists) {
                doc.ref.delete();
            }
        });

        console.log("Deleted the Posts of the Arch Enemy Later");
    });
});

exports.onCreateActivityFeedItem = functions.firestore.document('/feed/{userId}/feedItems/{activityFeedItem}').onCreate(async (snapshot, context) => {
    console.log("Activity Feed Item Created", snapshot.data());

    // get the user Connected to the FEED
    const userId = context.params.userId;

    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();


    // Once if we have user check for notification Token
    const androidNotificationToken = doc.data().androidNotificationToken;

    if (androidNotificationToken) {
        sendNotification(androidNotificationToken, snapshot.data());
    } else {
        console.log("No Token for User Unable to send Notification");
    }


    function sendNotification(androidNotificationToken, activityFeedItem) {

        let body;

        // Switch body value based of notification Type
        switch (activityFeedItem.type) {
            case "comment": body = `${
                    activityFeedItem.username
                } commented: ${
                    activityFeedItem.commentData
                }`;
                break;

            case "like": body = `${
                    activityFeedItem.username
                } loved your post ❤`;
                break;

            case "follow": body = `${
                    activityFeedItem.username
                } started following you`;
                break;

            default:
                break;
        }


        // Create a message for push notification
        const message = {
            notification: {
                body
            },
            token: androidNotificationToken,
            data: {
                recipient: userId
            }
        };

        // Send Message with Admin Messaging

        admin.messaging().send(message).then(response => {
            console.log("Successfully sent Message", response);
        }).catch(error => {
            console.log("Error sending Message", error)
        });
    }
});
