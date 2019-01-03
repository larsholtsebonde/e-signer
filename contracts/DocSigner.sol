pragma solidity ^0.5.2;

/**
 * @title A smart contract to sign electronic records on the blockchain to obtain tamper-proof transparent audit trails.
 * @author https://github.com/larsholtsebonde
 * @notice No guarantees, not production ready.
 * @notice No maximum number of required signees. Too many signees can lead to out-of-gas issues
 */

contract DocSigner {


    struct Signature {
        address signee; // Address of signee
        bool signed; // Whether or not the signee has signed
        string role; // Role of signee
        string comment; // Signee's comment to the signature
        bool approved; // Outcome of signature
        uint blockNumber; // Number of the block in which the signature was added
        uint timestamp; // Unix timestamp of when the signature was signed
    }


    struct Document {
        address docOwner; // Adddress of document owner (the one who submitted the document for signatures)
        string docHash; // Document hash for document verification
        address[] requiredSignees; // Array of required signee addresses
        mapping(address => Signature) signatures; // Array of signatures identified by address of signee
        uint numberApprovals; // Number of signatures approving the document
        bool locked; // Whether or not the document is locked
        bool approved; // Whether or not the document is approved
        bool inApprovalFlow; // Whether or not the document is in an approval flow
        uint blockNumberStatus; // Number of the block in which the current status was effectuated
        uint timestampStatus; // Timestamp of when the current status was effectuated
    }


    string public organization; // Name of organization
    mapping(address => bool) private _approvedFlowStarters; // Array of addresses that can start and cancel approval flows
    mapping(address => bool) private _admins; // Array of addresses that can add and revoke the ability to start approval flows
    mapping(string => Document) private _documents; // Array of documents identified by a string id (ID management is handled on client side)


    /** Events **/
    event ApprovalFlowStarted(string docId);
    event DocumentSigned(string docId, address indexed signee, string role);
    event DocumentApproved(string docId);
    event DocumentRejected(string docId, address indexed signee, string role);


    /**
     * @dev Initialize contract with an organization name
     * @param _organization The name of the organization using the contract instance
     */
    constructor(string memory _organization) public {
        organization = _organization;
        _admins[msg.sender] = true;
    }


    /**
     * @dev Revert transaction if funds are transferred to the contract
     */
    function () external payable {
        revert();
    }


    /**
     * @dev Add an address as approved signature flow starter
     * @param _flowstarter The address that can now start signature flows
     */
    function approveFlowStarter(address _flowstarter) external returns (bool success) {
        require(_admins[msg.sender]); // Only admins can add addresses as flow starters
        require(!_approvedFlowStarters[_flowstarter]); // Only approve if address is not already flow starter
        _approvedFlowStarters[_flowstarter] = true;
        return success;
    }


    /**
     * @dev Revoke an address as approved signature flow starter
     * @param _flowstarter The address that no longer can start signature flows
     */
    function revokeFlowStarter(address _flowstarter) external returns (bool success) {
        require(_admins[msg.sender]); // Only admins can revoke addresses as flow starters
        require(_approvedFlowStarters[_flowstarter]); // Only revoke if address is flow starter
        _approvedFlowStarters[_flowstarter] = false;
        return success;
    }


    /**
     * @dev Add an address as admin
     * @param _admin The address that is now an admin
     */
    function approveAdmin(address _admin) external returns (bool success) {
        require(_admins[msg.sender]); // Only admins can add admin privileges
        require(!_admins[_admin]); // Only approve if address is not already admin
        _admins[_admin] = true;
        return success;
    }


    /**
     * @dev Revoke an address as admin
     * @param _admin The address that is no longer an admin
     */
    function revokeAdmin(address _admin) external returns (bool success) {
        require(_admins[msg.sender]); // Only admins can revoke admin privileges
        require(_admins[_admin]); // Only revoke if address is admin
        _admins[_admin] = false;
        return success;
    }


    /**
     * @dev Start approval flow for a document
     * @param _docId The ID of the document
     * @param _docHash The hash of the document
     * @param _requiredSignees Array of addresses who need to sign the document
     */
    function startApprovalFlow(string calldata _docId, string calldata _docHash, address[] calldata _requiredSignees) external returns (bool success) {
        require(_approvedFlowStarters[msg.sender]); // Require that the sender is approved to start a signature flow
        require(_requiredSignees.length > 0); // Require minimum one signee
        require(!_documents[_docId].locked); // Can only add the document if it is not currently locked
        _documents[_docId].docOwner = msg.sender;
        _documents[_docId].docHash = _docHash;
        _documents[_docId].requiredSignees = _requiredSignees;
        _documents[_docId].locked = true;
        _documents[_docId].inApprovalFlow = true;
        _documents[_docId].blockNumberStatus = block.number;
        _documents[_docId].timestampStatus = block.timestamp;
        emit ApprovalFlowStarted(_docId);
        return true;
    }


    /**
     * @dev Function for a signee to sign a document
     * @param _docId The ID of the document to be signed
     * @param _role The role of the signee
     * @param _comment Signee's comment when signing the document
     * @param _approve Whether or not the signee approves the document
     */
    function signDocument(string calldata _docId, string calldata _role, string calldata _comment, bool _approve) external returns (bool success) {
        /** Requirement checks **/
        require(_documents[_docId].inApprovalFlow); // Require that the document is in an approval flow
        require(!_documents[_docId].signatures[msg.sender].signed); // Require that the signee hasn't already signe the document
        require(_checkRequiredSignee(msg.sender, _docId)); // Require that the signee is required to sign the document
        /** Build signature **/
        Signature memory _signature;
        _signature.signee = msg.sender;
        _signature.signed = true;
        _signature.role = _role;
        _signature.comment = _comment;
        _signature.approved = _approve;
        _signature.blockNumber = block.number;
        _signature.timestamp = block.timestamp;
        _documents[_docId].signatures[msg.sender] = _signature; // Add signature to document
        /** Update document status **/
        _documents[_docId].blockNumberStatus = block.number;
        _documents[_docId].timestampStatus = block.timestamp;
        emit DocumentSigned(_docId, msg.sender, _role);
        if (_approve) {
            _documents[_docId].numberApprovals += 1;
            if (_documents[_docId].numberApprovals == _documents[_docId].requiredSignees.length) {
                _approveDocument(_docId);
                emit DocumentApproved(_docId);
            }
        } else {
            _rejectDocument(_docId);
            emit DocumentRejected(_docId, msg.sender, _role);
        }
        return true;
    }


    /**
     * @dev Check whether a signee is required to sign the document
     * @param _signee The signee that might or might not be required to sign the document
     * @param _docId The ID of the document in question
     */
    function _checkRequiredSignee(address _signee, string memory _docId) private view returns (bool requiredSignee) {
        for (uint i = 0; i < _documents[_docId].requiredSignees.length; i++) {
            if (_documents[_docId].requiredSignees[i] == _signee) {
                return true; // Return true if the signee is required to sign the document
            }
        }
        return false;
    }


    /**
     * @dev Approve document
     * @param _docId The ID of the document to be approved
     */
    function _approveDocument(string memory _docId) private returns (bool success) {
        _documents[_docId].approved = true;
        _documents[_docId].inApprovalFlow = false;
        _documents[_docId].blockNumberStatus = block.number;
        _documents[_docId].timestampStatus = block.timestamp;
        return true;
    }


    /**
     * @dev Reject document
     * @param _docId The ID of the document to be rejected
     */
    function _rejectDocument(string memory _docId) private returns (bool success) {
        _documents[_docId].inApprovalFlow = false;
        _documents[_docId].blockNumberStatus = block.number;
        _documents[_docId].timestampStatus = block.timestamp;
        return true;
    }


    /**
     * @dev Check if an address is admin
     * @param _address The address that is checked whether is an admin
     */
     function checkIsAdmin(address _address) public view returns (bool isAdmin) {
         return _admins[_address];
     }


     /**
     * @dev Check if an address is approved flow starter
     * @param _address The address that is checked whether is an approved flow starter
     */
     function checkIsFlowStarter(address _address) public view returns (bool isFlowStarter) {
         return _approvedFlowStarters[_address];
     }


     /**
      * @dev Return document attributes for a specific document
      * @param _docId The id of the document for which the attributes are returned
      */
     function getDocument(string memory _docId) public view returns (address docOwner, string memory docHash, address[] memory requiredSignees, uint numberApprovals, bool locked, bool approved, bool inApprovalFlow, uint blockNumberStatus, uint timestampStatus) {
         Document memory _document = _documents[_docId];
         return (_document.docOwner, _document.docHash, _document.requiredSignees, _document.numberApprovals, _document.locked, _document.approved, _document.inApprovalFlow, _document.blockNumberStatus, _document.timestampStatus);
     }


     /**
      * @dev Return signature attributes for a specific signature
      * @param _docId The id of the document that the signature is on
      * @param _signee The address of the signee of the signature
      */
      function getSignature(string memory _docId, address _signee) public view returns (address signee, bool signed, string memory role, string memory comment, bool approved, uint blockNumber, uint timestamp) {
          Signature memory _signature = _documents[_docId].signatures[_signee];
          return (_signature.signee, _signature.signed, _signature.role, _signature.comment, _signature.approved, _signature.blockNumber, _signature.timestamp);
      }


      /**
       * @dev Return name of organization that owns the contract
       */
      function getOrganizationName() public view returns (string memory organizationName) {
          return organization;
      }
}
