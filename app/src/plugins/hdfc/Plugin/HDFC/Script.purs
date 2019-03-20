module Plugin.HDFC.Script where

import Prelude

import Data.Argonaut.Core as JSON

submitUsername :: String
submitUsername = try "{{interface}}.onCommandDone(e)"
  """
    var loginFrame = document.getElementsByName("login_page")[0]
    var loginDoc = loginFrame.contentDocument;
    var userId = loginDoc.getElementsByName("fldLoginUserId")[0];
    userId.value = "{{username}}";
    var anchors = Array.from(loginDoc.getElementsByTagName("a"));
    var continueButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/fLogon\(\)/))[0];
    loginFrame.addEventListener("load", () => {{interface}}.onCommandDone());
    continueButton.click();
  """

submitPassword :: String
submitPassword = try "{{interface}}.onCommandDone(e)"
  """
    var loginFrame = document.getElementsByName("login_page")[0]
    var loginDoc = loginFrame.contentDocument;
    var password = loginDoc.getElementsByName("fldPassword")[0];
    password.value = "{{password}}";
    var secureAccess = loginDoc.getElementsByName("chkrsastu")[0];
    secureAccess.checked = true;
    var anchors = Array.from(loginDoc.getElementsByTagName("a"));
    var loginButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/fLogon\(\)/))[0];
    loginButton.click();
  """

isOtpPage :: String
isOtpPage = try "{{interface}}.onCommandDone(\"false\")"
  """
    var isOtpPage = document.getElementsByName("fldMobile").length > 0;
    {{interface}}.onCommandDone(isOtpPage.toString());
  """


fireOtp :: String
fireOtp = try "{{interface}}.onCommandDone(e)"
  """
    var mobileCheck = document.getElementsByName("fldMobile")[0];
    mobileCheck.checked = true;
    var anchors = Array.from(document.getElementsByTagName("a"));
    var continueButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/fireOtp\(\)/))[0];
    continueButton.click();
  """

isOtpEntryPage :: String
isOtpEntryPage = try "{{interface}}.onCommandDone(\"false\")"
  """
    var isOTPEntryPage = document.getElementsByName("fldOtpToken").length > 0;
    {{interface}}.onCommandDone(isOTPEntryPage.toString());
  """

submitOtp :: String
submitOtp = try "{{interface}}.onCommandDone(e)"
  """
    var otpField = document.getElementsByName("fldOtpToken")[0];
    otpField.value = "{{otp}}";
    var anchors = Array.from(document.getElementsByTagName("a"));
    var continueButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/authOtp\(\)/))[0];
    continueButton.click();
  """

isNBHome :: String
isNBHome = try "{{interface}}.onCommandDone(\"false\");"
  """
    var mainFrame = document.getElementsByName("main_part")[0]
    var mainDoc = mainFrame.contentDocument;
    var isNBHome = mainDoc.getElementsByClassName("PSMSubHeader").length > 0
    {{interface}}.onCommandDone(isNBHome.toString());
  """

openEnquiry :: String
openEnquiry = try "{{interface}}.onCommandDone(e);"
  """
    var leftMenu = document.getElementsByName("left_menu")[0];
    var leftMenuDoc = leftMenu.contentDocument;
    var enquireButton = leftMenuDoc.getElementById("enquiryatag");
    var observer = new MutationObserver(function() {
    	observer.disconnect();
    	{{interface}}.onCommandDone(true);
    });
    var enquiryTab = leftMenuDoc.querySelector('#enquirytab');
    observer.observe(enquiryTab, {attributes:true, subtree: true});
    enquireButton.click();
  """

selectAccountBalance :: String
selectAccountBalance = try "{{interface}}.onCommandDone(e);"
  """
    var leftMenu = document.getElementsByName("left_menu")[0];
    var leftMenuDoc = leftMenu.contentDocument;
    var enquireButton = leftMenuDoc.getElementById("enquiryatag")
    var viewBalanceButton = leftMenuDoc.getElementById("SBI_nohref");
    var mainFrame = document.getElementsByName("main_part")[0];
    mainFrame.addEventListener('load', function() {
      {{interface}}.onCommandDone(true);
    })
    viewBalanceButton.click();
  """

getBalances :: String
getBalances = try "{{interface}}.onCommandDone(e);"
  """
    var mainFrame = document.getElementsByName("main_part")[0];
    var mainDoc = mainFrame.contentDocument;
    var accountType = mainDoc.getElementsByName("selAccttype")[0];
    accountType.value = "SCA";
    accountType.addEventListener('change', function() {
      var account = mainDoc.getElementsByName("selAcct")[0];
      var accounts = Array.from(account.children).slice(1).map(a => a.value);
      var viewButton = mainDoc.getElementsByClassName('viewBtn')[0];
      var balanceTasks = accounts.map(acc => new Promise((resolve, reject) => {
        account.value = acc;
        account.addEventListener('change', function() {
          var accountNum = acc.match(/\\d+/)[0];
          var frameLoad = function() {
              mainFrame.removeEventListener('load', frameLoad)
              mainDoc = mainFrame.contentDocument;
              var form = mainDoc.querySelector('form[name=frmTxn]');
              var balanceRow = Array.from(form.querySelector('.datatable').querySelectorAll('td')).find(td => td.innerHTML == 'Balance').parentElement
              var balance = balanceRow.children[1].innerHTML.replace(/<script(.*\\n)*.*<\\/script>/,"").replace(/,/g, "");
              resolve({account: accountNum, balance});
          }
          mainFrame.addEventListener('load', frameLoad);
          viewButton.click();
        })
        account.dispatchEvent(new Event('change'));
      }));
      Promise.all(balanceTasks).then(balances => {
        {{interface}}.onCommandDone(JSON.stringify(balances));
      });
    })
    accountType.dispatchEvent(new Event('change'));
  """

try :: String -> String -> String
try catchSnippet jsSnippet =
  "try { "
  <> jsSnippet <>
  " } catch(e) { "
  <> catchSnippet <>
  " }"

wrapInFunction :: String -> String
wrapInFunction jsSnippet =
  "(function(){ "
  <> jsSnippet <>
  "})();"
