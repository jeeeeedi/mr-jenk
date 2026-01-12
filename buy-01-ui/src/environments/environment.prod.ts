// src/environments/environment.prod.ts
// This is the PRODUCTION file for Docker builds
export const environment = {
  production: true,
  // Use same protocol as current page to avoid mixed content errors
  apiUrl: `${window.location.protocol}//${window.location.hostname}:8080/api`,
  apiGatewayUrl: `${window.location.protocol}//${window.location.hostname}:8080`,
  authUrl: `${window.location.protocol}//${window.location.hostname}:8080/api/auth`,
  usersUrl: `${window.location.protocol}//${window.location.hostname}:8080/api/users`,
  productsUrl: `${window.location.protocol}//${window.location.hostname}:8080/api/products`,
  mediaUrl: `${window.location.protocol}//${window.location.hostname}:8080/api/media`,
  enableDebugLogging: false,
  buildTimestamp: '2026-01-08T13:00:00Z',
};
