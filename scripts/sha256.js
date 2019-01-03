/**
 * Returns SHA-256 hash from supplied message.
 *
 * @param   {String} message.
 * @returns {String} hash as hex string.
 *
 * @example
 *   sha256('abc').then(hash => console.log(hash));
 *   const hash = await sha256('abc');
 */
async function sha256(message) {
    const msgUint8 = new TextEncoder('utf-8').encode(message);                      // encode as UTF-8
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);             // hash the message
    const hashArray = Array.from(new Uint8Array(hashBuffer));                       // convert hash to byte array
    const hashHex = hashArray.map(b => ('00' + b.toString(16)).slice(-2)).join(''); // convert bytes to hex string
    return hashHex;
}
