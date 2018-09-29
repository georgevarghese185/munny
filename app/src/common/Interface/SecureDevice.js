exports.isDeviceSecureImpl = function () {
  return Interface.isDeviceSecure();
};

exports.isUserAuthenticatedImpl = function() {
  return Interface.isUserAuthenticated();
}

exports.authenticateUserImpl = function (success, error) {
  Interface.authenticateUser(success, error);
};

exports.generateSecureKeyImpl = function (keyAlias, success, error) {
  Interface.generateSecureKey(keyAlias, success, error);
};

exports.generateSecureKeyWithUserAuthImpl = function (keyAlias, validFor, success, error) {
  Interface.generateSecureKeyWithUserAuth(keyAlias, validFor, success, error);
};

exports.secureEncryptImpl = function (data, keyAlias, success, error) {
  Interface.secureEncrypt(data, keyAlias, success, error);
};

exports.secureDecryptImpl = function (data, keyAlias, success, error) {
  Interface.secureDecrypt(data, keyAlias, success, error);
};
