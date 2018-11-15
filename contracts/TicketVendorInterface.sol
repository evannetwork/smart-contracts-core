pragma solidity ^0.4.20;


interface TicketVendorInterface {
    event TicketCreated(address indexed requester, uint256 indexed ticketId);

    /// @notice creates new ticket
    /// @dev callable by anyone
    /// emits TicketCreated
    /// @param value value to request, must be lte getTicketMinValue()
    function requestTicket(uint256 value) public;

    // update maximum age of price
    /// @notice tickets cannot be issued if this age is exceeded
    /// @dev callable by owner
    /// @param newPriceMaxAge new max age for price
    function setPriceMaxAge(uint256 newPriceMaxAge) public;

    /// @notice set query used when updating prices
    /// @param newQuery updated query
    function setQuery(string newQuery) public;

    /// @notice call oracle for pricing update
    /// @dev callable by owner / manager (tbd)
    function updatePrice() public payable;

    /// @notice get get current price and last update (as seconds since unix epoch)
    /// @return eveWeiPerEther current transfer rate (as Wei (home network) per EVE (even.network))
    /// @return lastUpdated timestamp of and last price update
    function getCurrentPrice() public view returns(
        uint256 eveWeiPerEther, uint256 lastUpdated, bool okay);

    /// @notice get max age that the price can have when issuing a ticket
    /// @return max age for price
    function getPriceMaxAge() public view returns(uint256);

    /// @notice get query used when updating prices
    /// @return oraclize URL query string
    function getQuery() public view returns(string);

    /// @notice get current number of tickets
    /// @return current number of tickets
    function getTicketCount() public view returns (uint256);

    /// @notice get ticket info
    /// @param ticketId id of the ticket to look up
    /// @return owner ticket owner
    /// @return price price, that has been locked for ticket
    /// @return validUntil expiration date for ticket
    /// @return value transfer value
    function getTicketInfo(uint256 ticketId) public view returns(
        address owner, uint256 price, uint256 issued, uint256 value);

    /// @notice check costs for updating price at oraclize
    /// @return cost for a price update
    function getUpdatePriceCost() public view returns (uint256 cost);
}