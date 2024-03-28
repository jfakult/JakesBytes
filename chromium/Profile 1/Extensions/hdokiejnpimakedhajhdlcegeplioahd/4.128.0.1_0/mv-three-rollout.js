/**
 * global variable to indicate if extension is installed
 * to perform auto-login
 * moved from legacy/background.js to make runtime.onInstall
 * listener register on first iteration of event registration
 */
var g_is_new_install = false

function loadScript(url) {
  const script = document.createElement('script')
  script.src = url
  script.type = 'text/javascript'
  script.async = false
  script.onerror = function() {
    console.log(url + 'failed to load')
  }
  document.head.appendChild(script)
}

;(function() {
  const isNewBackgroundEnabled = localStorage.getItem('enable_mv3_background')

  if (isNewBackgroundEnabled) {
    ;['background-redux-new.js',
	].forEach(script => loadScript(script))
  } else {
    ;[
      'logger.js',
      '228.background-redux.js',
	'316.background-redux.js',
	'381.background-redux.js',
	'393.background-redux.js',
	'508.background-redux.js',
	'71.background-redux.js',
	'889.background-redux.js',
	'893.background-redux.js',
	'899.background-redux.js',
	'95.background-redux.js',
	'956.background-redux.js',
	'background-redux.js',
	
      'oidc-client.min.js',
      'lpfulllib.js',
      'pwchanger.js',
      'forge.min.js',
      'jsOTP.js',
      'LPEventManager.js',
      'contentScriptInterface.js',
      'contentScriptDialogInterface.js',
      'tabDialogInterface.js',
      'extensionDropdownInterface.js',
      'extensionLoginDropdownInterface.js',
      'popoverInterface.js',
      'platformBackground.js',
      'LPNotifications.js',
      'platformBackgroundOverride.js',
      'federated-login-service.js',
      'extension-federated-login.js',
      'google-api-helpers.js',
      'prefs.js',
      'binary.js',
      'csid.js',
      'provisioning/provisioning.js',
      'acctsiframe-background.js',
      'verboseLoggerHooks.js',
      'reduxProxies.js',
      'background.js',
      'context-menu.js',
      'LPTab.js',
      'lpalerts.js',
      'newserver.js',
      'serverIndividualSharing.js',
      'vaultHistory.js',
      'serverSharedFolders.js',
      'serverIdentities.js',
      'serverEmergencyAccess.js',
      'serverSitesNotes.js',
      'backgroundServer.js',
      'server.js',
      'icons.js',
      'fromcs.js',
      'db.js',
      'generate.js',
      'namedpipes.js',
      'rsakeys.js',
      'fftranslations.js',
      'cc.js',
      'partner.js',
      'push_client.js',
      'cpwbot_bg.js',
      'websockets.js',
      'cpwbatch.js',
      'history.js',
      'checkpoint.js',
      'popupfilltab_bg.js',
      'background_debug.js',
      'heuristics_bg.js',
      'lpInfield_bg.js',
      'userFriendlyDescriptions.js',
      'loginTracking.js',
      'recordTypeConfig.js',
      'SiteLaunchObserver/siteLaunchObserverBG.js',
      'modules-background.js',
      'policies.js',
      'urlmatcher.js',
      'ravenTransport.js',
      'generateSharingKeys.js',
      'partnerBackground.js',
      'GenPassHistory.js',
      'FieldOverrides.js',
      'Recovery.js',
      'initialize-legacy-background.js'
    ].forEach(script => loadScript(script))

    if (typeof chrome !== 'undefined') {
      chrome.runtime.onInstalled.addListener(details => {
        if (details.reason === chrome.runtime.OnInstalledReason.INSTALL) {
          g_is_new_install = true
        }
      })
    } else if (typeof browser !== 'undefined') {
      browser.runtime.onInstalled.addListener(details => {
        if (details.reason === browser.runtime.OnInstalledReason.INSTALL) {
          g_is_new_install = true
        }
      })
    }
  }
})()
