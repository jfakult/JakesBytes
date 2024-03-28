/**
 * Dumb global function defined to avoid importing modules from zxcvbn-worker.js
 * as they are already included in offscreen-zxcvbn.html
 */
function importScripts() {
  // no op
}

chrome.runtime.onMessage.addListener(async message => {
  if (message.target !== 'offscreen-zxcvbn-doc') {
    return
  }

  switch (message.type) {
    case 'calculate-security-score':
      onMessage({
        ...message,
        data: JSON.parse(message.data)
      })
      break
    default:
      console.warn(`Unexpected message type received: '${message.type}'.`)
  }
})

function onMessage(e) {
  if (e.data.cmd === 'challengecomputescore_async') {
    startTime = new Date().getTime()
    challengecomputescore_async(
      e.data.curr,
      e.data.g_totalscore,
      JSON.parse(e.data.g_sites),
      e.data.g_aSites && e.data.g_aSites.length ? e.data.g_aSites : [],
      e.data.g_numsites,
      e.data.g_numblanksites,
      e.data.g_avgpasswordlength,
      e.data.g_aPasswords,
      e.data.g_MAXNUMCOMPUTESCORE,
      e.data.g_numduppasswords,
      e.data.g_numdupsites,
      e.data.g_usernames,
      e.data.WEAKPASSWORDSCORE,
      e.data.g_strengthscore,
      e.data.g_countscore,
      e.data.g_numweak,
      e.data.sharedavgstrength,
      e.data.SharedAccounts,
      e.data.g_runtimems,
      e.data.sfcounts,
      e.data.sharedstrengthscore,
      e.data.sharedblanksites,
      e.data.sharedweak,
      e.data.sharedavgpasswordlength,
      e.data.SharedPasswords,
      e.data.sharedcountscore,
      e.data.NonSharedAccounts,
      e.data.g_SFNames,
      e.data.AllSFNames,
      e.data.sharedtotalscore,
      e.data.g_numvulnerablesites,
      e.data.g_allPasswords,
      e.data.g_reuse,
      e.data.g_blanksites,
      e.data.g_allnumduppasswords,
      e.data.equivalentDomainCheckList,
      e.data.isExcludeSwitchedOn,
      e.data.excludedPasswords,
      e.data.domainsForAutomaticPasswordExclude,
      e.data.countReusedOnSharedItems,
      e.data.isFeatureEnabledSecurityDashboard2_0,
      e.data.dwmAlerts,
      e.data.isFeatureEnabledPasswordStrengthHardening
    )
  }
}

function postMessage(data) {
  chrome.runtime.sendMessage({
    challengeResult: {
      vaultScore: data.g_totalscore,
      passwordSecurityResults: data.g_aSites
    },
    type: 'calculate-security-score-result',
    ...data
  })
}
