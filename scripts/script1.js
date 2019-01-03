

function writeHash(hash) {
  document.getElementById("p-hash").innerHTML = "Hash: " + hash;
}

$(document).ready(function() {
  $("#button-hash").click(function() {
    var text = $("#text-input").val();
    sha256(text).then(function(result) {
      writeHash(result);
    });
  });
});
