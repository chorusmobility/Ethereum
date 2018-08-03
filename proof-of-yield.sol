contract ProofOfYieldProtocolV05 {
    address private owner;
    address private ERC20TokenAddress;

    VickreyAuction private auction;
    uint256 public endOfBidding;
    uint256 public endOfRevealing;

    
    //Update that fields for separate object with location. then should be with sharding
    string private owner_positionOrigin;
    string private owner_positionDestination;
    
    // Minimum limit for transaction based on contract
    uint private limit;
    
        /* Constructor */
    function ProofOfYieldProtocolV05() public {
        owner = msg.sender;
        //then for init just call: updateTokenAddress(_tokenAddress);
    }
    
    function getMinLimit() public view returns (uint) {
        return limit;
    }
 
    //Update method for object comparison
    function updateCurrentLocation(string currentLocation_new) public{
        owner_positionOrigin = currentLocation_new;
    }
    
    function updateDestinationLocation(string location_new) public{
        owner_positionDestination = location_new;
    }
    
    function reachedDestination() public view returns (bool) {
        return keccak256(owner_positionOrigin) == keccak256(owner_positionDestination);
    }
    
    function reveal(uint256 amount, uint256 nonce) public {
        auction.reveal(amount, nonce);
    }
    
    //Update implementation for analyzing acceptable area
    function verifyPositionChange() public payable returns (bool){
        //TODO: create function or ask for the location in the zone of destination with some radius.
        bool changed = keccak256(owner_positionOrigin) == keccak256(owner_positionDestination);
        if (changed) {
            auction.withdraw();
        }
        return changed;
    }
    
    
    //beware of that modifications for non owner users
    function initChangePositionRequest(address addressA, address addressB, string locationX, string locationY, uint value) public {
        //TODO: check is auction exists and does it empty
        //require(!auction.isActive());
        
        auction = new VickreyAuction(IERC20Token(ERC20TokenAddress), limit, 3 minutes, 2 minutes);
        require(msg.sender != owner);

        auction.bid(keccak256(value, msg.sender));
        
        if (keccak256(owner_positionOrigin) != keccak256(locationX)) {
            //do update fields logic
            updateCurrentLocation(locationX);
        }
        
        updateDestinationLocation(locationY);
        
    }
    
    // Method modifier. Dening invoking contract owner's functions.
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Methods removing contract in case of empty balance. Otherwise returns error.
    function kill() public isOwner {
        require(this.balance == 0);
        selfdestruct(owner);
    }
    
    //Update limit for new one 
    function updateLimit(uint newLimit) public isOwner {
        limit = newLimit;
    }
    
    //Update address of custom token
    function updateTokenAddress(address newAddress) public isOwner {
        ERC20TokenAddress = newAddress;
    }
    
    // Method verifying reached limit or available funds on balance for withdraw.
    // Because of nothing changing within method we are using modifier "constant"
    //function canWithdraw() public constant returns (bool) {
    //    return this.balance >= limit;
    //}
    
}