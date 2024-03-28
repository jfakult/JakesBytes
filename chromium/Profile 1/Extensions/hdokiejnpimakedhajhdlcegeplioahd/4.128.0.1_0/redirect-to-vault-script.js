/**
 * Runs at document start
 * to redirect users to web vault on successful registration
 * and avoid showing them create account success page
 * and ask them to download extension if extension already installed
 * redirection handled by apps/extension/background/src/sagas/redirect-to-vault-on-acct-create-success.ts
 * only for new mv3 background
 */

const runtime =
  typeof browser !== 'undefined' ? browser.runtime : chrome.runtime

runtime.sendMessage('redirectToVaultOnCreateAccountSuccess')
