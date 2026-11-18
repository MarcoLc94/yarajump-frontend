// Service worker de notificaciones push (Firebase Cloud Messaging) para la PWA.
// Lo registra window.yaraPush (index.html) con scope /app/push/.
// Con la app cerrada o en segundo plano, Firebase muestra la notificación del mensaje
// y al tocarla abre webpush.fcm_options.link (lo pone el backend: /app/).
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBRo9MAajsEeusbrcX47U4yj6gG1ZbJI9I',
  authDomain: 'yara-jump.firebaseapp.com',
  projectId: 'yara-jump',
  storageBucket: 'yara-jump.firebasestorage.app',
  messagingSenderId: '725442947574',
  appId: '1:725442947574:web:d9b43f77c7fd8a34ef7fd7',
});

firebase.messaging();
