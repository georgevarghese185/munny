exports.isDeviceSecureImpl = function () {
  return Interface.isDeviceSecure();
};

exports.isUserAuthenticatedImpl = function() {
  return Interface.isUserAuthenticated();
}

exports.authenticateUserImpl = function (success, error) {
  Interface.authenticateUser(success, error);
};

exports.secureEncryptImpl = function (data, keyAlias, success, error, authorized) {
  Interface.secureEncrypt(data, keyAlias, success, error, authorized);
};

exports.secureDecryptImpl = function (data, keyAlias, success, error, authorized) {
  Interface.secureDecrypt(data, keyAlias, success, error, authorized);
};
