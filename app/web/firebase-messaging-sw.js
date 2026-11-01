// Shows web pushes while no PraiseTeam tab is in front. The Firebase JS SDK
// version matches firebase_core_web (supportedFirebaseJsSdkVersion); the
// config is the web app's public one from lib/firebase_options.dart.
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCP7F4RL7ONrlJbFwbcZYpIIHoTKd_i6bU',
  appId: '1:677984922607:web:0a96fe62abac4f5dcd241a',
  messagingSenderId: '677984922607',
  projectId: 'praiseteam-sg',
  authDomain: 'praiseteam-sg.firebaseapp.com',
});
firebase.messaging();
