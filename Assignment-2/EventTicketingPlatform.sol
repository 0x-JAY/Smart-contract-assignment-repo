// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

contract EventTicketingPlatform {

// Classify Event
enum EventType {
    None,
    Conference,
    Workshop,
    Hackathon,
    Meetup,
    Webinar,
    Summit
}

// Tiket Access Level
enum TicketTier{
    Standard,
    Primium,
    VIP
}

struct Ticket {
    uint256 ticketId;
    address buyer;
    string eventName;
    uint256 purchaseAmount;
    uint256 purchaseTimestamp;
    uint256 eventTimestamp;
    EventType eventType;
    TicketTier ticketTier;
}

mapping (uint256 => Ticket) public tickets;
mapping (uint256 => bool) public ticketUsed;

uint256 public totalTicketsSold;
address public owner;

error EventTicketingPlatform_Not_Authorized();
error EventTicketingPlatform_Invalid_Amount();
error EventTicketingPlatform_Select_Event_Type();
error EventTicketingPlatform_Invalid_Event_Date();
error EventTicketingPlatform_Ticket_Exists();
error EventTicketingPlatform_Ticket_does_not_exist();

event TicketPurchased(
    uint256 indexed ticketId,
    address indexed buyer,
    string eventName,
    uint256 amountPaid,
    EventType eventType
);

modifier onlyOwner() {
    if (msg.sender != owner)
    revert EventTicketingPlatform_Not_Authorized();
    _;
}

function purchaseTicket(
    uint256 _ticketId, 
    string memory _eventName, 
    uint256 _eventTimestamp,
    EventType _eventType,
    TicketTier _ticketTier) payable external {
    
    // Guard 1: Reject any transaction where the payment amount is zero 
    if (msg.value == 0) {
        revert EventTicketingPlatform_Invalid_Amount();
    }

    // Guard 2:  Reject any purchase containing an invalid event type
    if(_eventType == EventType.None){
        revert EventTicketingPlatform_Select_Event_Type();
    }

    // Guard 3: Reject registrations where the supplied event date is not in the future. Throw: "Invalid Event Date"
    if(_eventTimestamp <= block.timestamp){
        revert EventTicketingPlatform_Invalid_Event_Date();
    }

    // Guard 4: Query the tracking mapping to ensure the proposed ticket ID has not been used previously. Throw: "Ticket Exists"
    if(ticketUsed[_ticketId]){
        revert EventTicketingPlatform_Ticket_Exists();
    }
    
    tickets[_ticketId] = Ticket({
        ticketId: _ticketId,
        buyer: msg.sender,
        eventName: _eventName,
        purchaseAmount: msg.value,
        purchaseTimestamp:block.timestamp,
        eventTimestamp: _eventTimestamp,
        eventType: _eventType,
        ticketTier: _ticketTier
    });
    
    ticketUsed[_ticketId] = true;
    totalTicketsSold++; 

    emit TicketPurchased(
        _ticketId,
        msg.sender,
        _eventName,
        msg.value,
        _eventType
    );
}

function getDaysUntilEvent(uint256 _ticketId) public view returns(uint256 daysRemaining) {
    // Ensure the requested ticket record exists before running calculations. Throw: "Ticket does not exist"
    if (!ticketUsed[_ticketId]) {
        revert EventTicketingPlatform_Ticket_does_not_exist();
    }

    Ticket storage ticket = tickets[_ticketId];

    if (block.timestamp >= ticket.eventTimestamp) {
        return 0;
    }
    
    return (ticket.eventTimestamp - block.timestamp)/1 days;
}


function calculateRefundAmount (uint256 _ticketId) public view returns (uint256 refundAmount)
    {
        if (!ticketUsed[_ticketId]) {
            revert EventTicketingPlatform_Ticket_does_not_exist();
        }

        Ticket storage ticket = tickets[_ticketId];

        // 1. Determine the current number of days remaining by calling getDaysUntilEvent. 
        uint256 days_Remaining = getDaysUntilEvent(_ticketId);
        
        // 2. Apply the platform refund policy based on the remaining time before the event.
        /*Refund Policy:
        
            30 Days or More 80% ✅
            15 – 29 Days 50% ✅
            7 – 14 Days 25% ✅
            Less Than 7 Days 0% ✅
        */ 
        uint256 refund_Percentage;
        if (days_Remaining >= 30){
           refund_Percentage = 80;
        }else if (days_Remaining >= 15){
           refund_Percentage = 50;
        }else if (days_Remaining >= 7){
           refund_Percentage = 25;
        }else {
           refund_Percentage = 0;
        }

        // 3. Return the calculated refund amount.
        return (ticket.purchaseAmount * refund_Percentage)/ 100;
    }

    function getTicketSummary(uint256 _ticketId) external view 
    returns(address buyer, uint256 purchaseAmount, TicketTier Tier)
    {
        // Verify the requested ticket exists before processing. 
        if (!ticketUsed[_ticketId]) {
            revert EventTicketingPlatform_Ticket_does_not_exist();
        }

        Ticket storage ticket = tickets[_ticketId];

        // 1. The buyer address (to verify ticket ownership).
        // 2. The purchase amount in Wei (to verify payment value). 
        // 3. The ticket tier enum value (to verify access privileges).
        return(ticket.buyer, ticket.purchaseAmount, ticket.ticketTier); 
    }
}