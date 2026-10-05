// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CorporateTreasury {
    // Requirement A: An enum used to track geographical data. 
    // It must prevent default-value errors by defining its zero-index explicitly as a fallback option:
    enum Continent{
        None,
        NorthAmerica, 
        Europe, 
        Asia, 
        Oceania, 
        SouthAmerica, 
        Africa   
    }

    // An enum used to tag the underlying asset's legal structure
    enum AssetClass{
        Equity, 
        FixedIncome, 
        Crypto, 
        RealEstate
    }

    // Requirement B: Struct
    struct Investment {
        uint256 id; /*The tracking key assigned to the record. */
        address investor; /*The public key wallet address that initiated the payment. */
        string assetName; /*The human-readable ticker name of the asset (e.g., "BTC", "AAPL"). */
        uint256 principal; /*The raw deposit amount measured in base units (Wei). */
        uint256 timestamp; /*The strict block execution time (block.timestamp). */
        Continent continent; /*The assigned region enum value.*/
        AssetClass assetClass; /*The assigned financial category enum value.*/
    }

    // Requirement C: Ledger State Storage & Mappings
    mapping(uint256 => Investment) public ledger;
    mapping(uint256 => bool) public idUsed;

    uint256 public totalInvestmentsCount;
    address public owner; 

    // Coustom Errors:
    error CorporateTreasury_Not_Authorised();
    error CorporateTreasury_Not_Enough_Value();
    error CorporateTreasury_Select_Location();
    error CorporateTreasury_ID_Exists();
    error CorporateTreasury_Investment_does_not_Exists();

    // Requirement D: Access Control & Defensive Modifiers
    modifier onlyOwner() {
       if (msg.sender!= owner) {
         revert CorporateTreasury_Not_Authorised();
        }
        _;
    }

    // Events
    event InvestmentRecorded(
        uint id, 
        address investor,
        string assetName, 
        uint256 principal, 
        Continent
    );

    // Function Interface Manifest
    function addInvestment(
        uint256 _id, 
        string memory _assetName, 
        Continent _continent, 
        AssetClass 
        _assetClass
        ) external payable {
        // 1. Reject any transaction where the financial payload value is zero. Throw: "Invalid Amount". 
            if (msg.value <= 0){
                revert CorporateTreasury_Not_Enough_Value();
            }

        // 2. Reject any structural registration containing an invalid geographic configuration (Continent.None). Throw: "Select Continent". 
        if (_continent == Continent.None){
            revert CorporateTreasury_Select_Location();
        }
        
        // 3. Query the security mapping to ensure the proposed transaction ID hasn't been used. Throw: "ID Exists". 
        if (idUsed[_id]){
            revert CorporateTreasury_ID_Exists();
        }
        
        // 4. Write the packed tx data directly to ledger mapping 
        ledger[_id] = Investment({
            id: _id,
            investor:  msg.sender,
            assetName: _assetName,
            principal: msg.value,
            timestamp: block.timestamp,
            continent: _continent,
            assetClass: _assetClass
        });

        // 5. Update idUsed and totalInvestmentCount 
        idUsed[_id] = true;
        totalInvestmentsCount++;
        
        // 6. emit InvestmentRecorded(_id, msg.sender, _assetName, msg.value, _continent); 
        emit InvestmentRecorded(_id, msg.sender, _assetName, msg.value, _continent);
    }   

    function getDaysUnderManagement(uint256 _id) public view returns (uint256 daysUnderMgmt){
        /* Guard Rule: Ensure the requested record exists before running data operations. 
         Throw: "Investment does not exist". */
         if(!idUsed[_id]){
            revert CorporateTreasury_Investment_does_not_Exists();  
         }

         /* Calculate and return the elapsed days under management. */
        daysUnderMgmt = (block.timestamp - ledger[_id].timestamp)/1 days;
    }
    
    function calculateYield(uint256 _id) public view returns (uint256 accruedYield) {
        // Verify the record exists before processing calculations. Throw: "Investment does not exist".
        if(!idUsed[_id]){
            revert CorporateTreasury_Investment_does_not_Exists();  
        }

        //  Calculate the current days active by calling getDaysUnderManagement. 
        uint256 activeDays = getDaysUnderManagement(_id); 
        Investment memory investment = ledger[_id];

        /*
         If the active runtime resolves to 0 whole days, instantly return an output value of 0. 
         Otherwise, run the precision scaler formula using an active baseline integer parameter of 5.
        */
        if(activeDays == 0){
         return accruedYield = 0;
        }

        uint256 baseInt = 5;

        accruedYield = (investment.principal * activeDays * baseInt)/36500;
    } 

    function getInvestmentSummary(uint256 _id) external view returns (
         address investor, 
         uint256 principal,
         Continent continent 
        ) 
        {
           if(!idUsed[_id]){
            /* Verify the record exists before processing calculations. Throw: "Investment does not exist".*/
             revert CorporateTreasury_Investment_does_not_Exists();  
           }
           
            Investment memory investment = ledger[_id];
            /*Actions: Instead of returning the entire complex struct (which can be clunky for external interfaces to unpack), 
            extract and return only the three core data points specified in the assignment manifest: */
                // a. The investor address (to verify ownership). 
                // b. The principal amount in Wei (to check the deposit size). 
                // c. The continent enum value (to verify geographical compliance). 
                return (investment.investor, investment.principal, investment.continent);
    }   
}
