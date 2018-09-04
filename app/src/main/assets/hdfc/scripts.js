//submit_username
var loginFrame = document.getElementsByName("login_page")[0]
var loginDoc = loginFrame.contentDocument;
var userId = loginDoc.getElementsByName("fldLoginUserId")[0];
userId.value = "{{username}}";
var anchors = Array.from(loginDoc.getElementsByTagName("a"));
var continueButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/fLogon\(\)/))[0];
loginFrame.addEventListener("load", () => {{interface}}.onCommandDone());
continueButton.click();
//end


//submit_password_login
var loginFrame = document.getElementsByName("login_page")[0]
var loginDoc = loginFrame.contentDocument;
var password = loginDoc.getElementsByName("fldPassword")[0];
password.value = "{{password}}";
var secureAccess = loginDoc.getElementsByName("chkrsastu")[0];
secureAccess.checked = true;
var anchors = Array.from(loginDoc.getElementsByTagName("a"));
var loginButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/fLogon\(\)/))[0];
loginButton.click();
//end


//is_otp_page
var isOtpPage = document.getElementsByName("fldMobile").length > 0;
{{interface}}.onCommandDone(isOtpPage.toString());
//end


//fire_otp
var mobileCheck = document.getElementsByName("fldMobile")[0];
mobileCheck.checked = true;
var anchors = Array.from(document.getElementsByTagName("a"));
var continueButton = anchors.filter(a => a.getAttribute("onclick") && a.getAttribute("onclick").match(/fireOtp\(\)/))[0];
continueButton.click();
//end