
const ropstenAddress = "0xD7D76034586E35E3bdf88FDE227f798D5EaAF0b7";
var abi;
fetch('./contracts/DocSigner.abi')
.then(response => response.json())
.then(data => abi = data);


function getWriteOrganizationName(contractInstance) {
  contractInstance.getOrganizationName((error, organization) => {
    document.getElementById("p-organization-name").innerHTML = "Organization: " + organization
  });
}


function getWriteCheckIsAdmin(contractInstance, address) {
  contractInstance.checkIsAdmin(address, (error, isAdmin) => {
    document.getElementById("p-is-admin").innerHTML = "Is <i>" + address + "</i> admin: <b>" + isAdmin + "</b>";
  });
}


function getWriteCheckIsFlowStarter(contractInstance, address) {
  contractInstance.checkIsFlowStarter(address, (error, isFlowStarter) => {
    document.getElementById("p-is-flow-starter").innerHTML = "Is <i>" + address + "</i> flow strater: <b>" + isFlowStarter + "</b>";
  });
}

function checkAddress(address) {
  if (!web3.isAddress(address)) {
    alert("Invalid address!");
    return false;
  } else {
    return true;
  }
}


$(document).ready(function() {
  $("#button-approve-flow-starter").click(function() {
    var address = $("#input-approve-flow-starter").val();
    if (!checkAddress(address)) {
      return false;
    }
    var contract = web3.eth.contract(abi);
    web3.version.getNetwork((error, networkId) => {
      switch (networkId) {
        case "3":
          var contractInstance = contract.at(ropstenAddress);
          break
        default:
          var contractInstance = null;
      }
      contractInstance.approveFlowStarter(address, (error, result) => {
        if (!error) {
          console.log(result);
        } else {
          console.log(error);
        }
      });
    });
  });


  $("#button-revoke-flow-starter").click(function() {
    var address = $("#input-revoke-flow-starter").val();
    if (!checkAddress(address)) {
      return false;
    }
    var contract = web3.eth.contract(abi);
    web3.version.getNetwork((error, networkId) => {
      switch (networkId) {
        case "3":
          var contractInstance = contract.at(ropstenAddress);
          break
        default:
          var contractInstance = null;
      }
      contractInstance.revokeFlowStarter(address, (error, result) => {
        if (!error) {
          console.log(result);
        } else {
          console.log(error);
        }
      });
    });
  });


  $("#button-start-approval-flow").click(function() {
    var docId = $("#input-start-approval-flow-doc-id").val();
    var docHash = $("#input-start-approval-flow-doc-hash").val();
    var signees = new Array(0);
    var signee = $("#input-start-approval-flow-signee").val();
    if (!checkAddress(signee)) {
      return false;
    }
    signees.push(signee);
    if (docId.length <= 0) {
      alert("Please fill document ID");
    }
    var contract = web3.eth.contract(abi);
    web3.version.getNetwork((error, networkId) => {
      switch (networkId) {
        case "3":
          var contractInstance = contract.at(ropstenAddress);
          break
        default:
          var contractInstance = null;
      }
      contractInstance.startApprovalFlow(docId, docHash, signees, (error, result) => {
        if (!error) {
          console.log(result);
        } else {
          console.log(error);
        }
      });
    });
  });


  $("#button-sign-document").click(function() {
    var docId = $("#input-sign-document-doc-id").val();
    var role = $("#input-sign-document-role").val();
    var comment = $("#input-sign-document-comment").val();
    var approve = ($('input[name=input-sign-document-approval]:checked').val() == 'true');
    var contract = web3.eth.contract(abi);
    web3.version.getNetwork((error, networkId) => {
      switch (networkId) {
        case "3":
          var contractInstance = contract.at(ropstenAddress);
          break
        default:
          var contractInstance = null;
      }
      contractInstance.signDocument(docId, role, comment, approve, (error, result) => {
        if (!error) {
          console.log(result);
        } else {
          console.log(error);
        }
      });
    });
  });


  $("#button-get-document").click(function() {
    var docId = $("#input-get-document-doc-id").val();
    var contract = web3.eth.contract(abi);
    web3.version.getNetwork((error, networkId) => {
      switch (networkId) {
        case "3":
          var contractInstance = contract.at(ropstenAddress);
          break
        default:
          var contractInstance = null;
      }
      contractInstance.getDocument(docId, (error, doc) => {
        if (!error) {
          console.log("Document owner: " + doc[0]);
          console.log("Document hash: " + doc[1]);
          console.log("Required signees: " + doc[2]);
          console.log("Number of approvals: " + doc[3]);
          console.log("Document locked: " + doc[4]);
          console.log("Document approved: " + doc[5]);
          console.log("Document in approval flow: " + doc[6]);
          console.log("Status per block number: " + doc[7]);
          console.log("Status per timestamp: " + doc[8]);
        } else {
          console.log(error);
        }
      });
    });
  });


  $("#button-get-signature").click(function() {
    var docId = $("#input-get-signature-doc-id").val();
    var signee = $("#input-get-signature-signee").val();
    if (!checkAddress(signee)) {
      return false;
    }
    var contract = web3.eth.contract(abi);
    web3.version.getNetwork((error, networkId) => {
      switch (networkId) {
        case "3":
          var contractInstance = contract.at(ropstenAddress);
          break
        default:
          var contractInstance = null;
      }
      contractInstance.getSignature(docId, signee, (error, signature) => {
        if (!error) {
          console.log("Signee: " + signature[0]);
          console.log("Signed: " + signature[1]);
          console.log("Role: " + signature[2]);
          console.log("Comment: " + signature[3]);
          console.log("Approved: " + signature[4]);
          console.log("Signature block number: " + signature[5]);
          console.log("Signature timestamp: " + signature[6]);
        } else {
          console.log(error);
        }
      });
    });
  });
});


window.addEventListener('load', async() => {
  if (window.ethereum) {
    window.web3 = new Web3(ethereum);
    try {
      await ethereum.enable();
      const contract = web3.eth.contract(abi);
      web3.version.getNetwork((error, networkId) => {
        switch (networkId) {
          case "3":
            var contractInstance = contract.at(ropstenAddress);
            break;
          default:
            var contractInstance = null;
        }
        if (contractInstance != null) {
          getWriteOrganizationName(contractInstance);
          getWriteCheckIsAdmin(contractInstance, web3.eth.accounts[0]);
          getWriteCheckIsFlowStarter(contractInstance, web3.eth.accounts[0]);
        } else{
          console.log("No contract instantiated");
        }
      });
    } catch (error) {
      console.log("Failed to connect to ethereum");
    }
  } else {
    console.log("Browser doesn't support web3 :'(");
  }
});
