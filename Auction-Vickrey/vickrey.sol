contract VickreyAuction {
    address seller;

    IERC20Token public token;
    uint256 public reservePrice;
    uint256 public endOfBidding;
    uint256 public endOfRevealing;

    address public highBidder;
    uint256 public highBid;
    uint256 public secondBid;

    mapping(address => bool) public revealed;

    function VickreyAuction(
        IERC20Token _token,
        uint256 _reservePrice,
        uint256 biddingPeriod,
        uint256 revealingPeriod
    )
        public
    {
        token = _token;
        reservePrice = _reservePrice;

        endOfBidding = now + biddingPeriod;
        endOfRevealing = endOfBidding + revealingPeriod;

        seller = msg.sender;

        highBidder = seller;
        highBid = reservePrice;
        secondBid = reservePrice;

        // the seller can't bid, but this simplifies withdrawal logic
        revealed[seller] = true;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => bytes32) public hashedBidOf;

    function bid(bytes32 hash) public payable {
        require(now < endOfBidding);
        require(msg.sender != seller);

        hashedBidOf[msg.sender] = hash;
        balanceOf[msg.sender] += msg.value;
        require(balanceOf[msg.sender] >= reservePrice);
    }

    function claim() public {
        require(now >= endOfRevealing);

        uint256 t = token.balanceOf(this);
        require(token.transfer(highBidder, t));
    }

    function withdraw() public {
        require(now >= endOfRevealing);
        require(revealed[msg.sender]);

        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function transfer(address from, address to, uint256 amount) private {
        balanceOf[to] += amount;
        balanceOf[from] -= amount;
    }
    
    function isActive() public view returns (bool) {
        return now >= endOfBidding && now < endOfRevealing;
    }

    function reveal(uint256 amount, uint256 nonce) public {
        require(now >= endOfBidding && now < endOfRevealing);

        require(keccak256(amount, nonce) == hashedBidOf[msg.sender]);

        require(!revealed[msg.sender]);
        revealed[msg.sender] = true;

        if (amount > balanceOf[msg.sender]) {
            // insufficient funds to cover bid amount, so ignore it
            return;
        }

        if (amount >= highBid) {
            // undo the previous escrow
            transfer(seller, highBidder, secondBid);

            // update the highest and second highest bids
            secondBid = highBid;
            highBid = amount;
            highBidder = msg.sender;

            // escrow an amount equal to the second highest bid
            transfer(highBidder, seller, secondBid);
        } else if (amount > secondBid) {
            // undo the previous escrow
            transfer(seller, highBidder, secondBid);

            // update the second highest bid
            secondBid = amount;

            // escrow an amount equal to the second highest bid
            transfer(highBidder, seller, secondBid);
       }
    }
}