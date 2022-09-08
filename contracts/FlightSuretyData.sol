//SPDX-License-Identifier: CC BY-NC-ND 4.0
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    struct Airline {
        string airlineName;
        address airlineAddress;
        bool isRegistered;
        bool isFunded;
    }
    struct Flight {
        string flightName;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    struct Passenger {
        address passengerAddress;
        bool isRegistered;
        uint256 balance;
    }
    struct Insurance {
        address passenger;
        uint256 amount;
        bool isCredited;
    }
    mapping(address => Airline) private airlines;
    mapping(bytes32 => Flight) private flights;
    mapping(address => Passenger) private passengers;
    mapping(bytes32 => Insurance[]) private insurances;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineRegistered(address airlineAddress);
    event AirlineFunded(address airlineAddress);
    event FlightRegistered(string flightName, address airlineAddress);
    event FlightStatusUpdated(
        string flightName,
        address airlineAddress,
        uint8 statusCode
    );
    event InsuranceCredited(
        address passengerAddress,
        string flightName,
        address airlineAddress,
        uint256 amount
    );
    event PassengerWithdrawn(
        address passengerAddress,
        string flightName,
        address airlineAddress,
        uint256 amount
    );

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() {
        contractOwner = msg.sender;
        airlines[contractOwner] = Airline({
            airlineName: "Airline 1",
            airlineAddress: contractOwner,
            isRegistered: true,
            isFunded: true
        });
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
     * @dev Modifier that requires the "Airline" to be registered
     */
    modifier requireAirlineRegistered(address airlineAddress) {
        require(
            airlines[airlineAddress].isRegistered,
            "Airline is not registered"
        );
        _;
    }

    /**
     * @dev Modifier that requires the "Airline" to be funded
     */
    modifier requireAirlineFunded(address airlineAddress) {
        require(airlines[airlineAddress].isFunded, "Airline is not funded");
        _;
    }

    /**
     * @dev Modifier that requires the "Flight" to be registered
     */
    modifier requireFlightRegistered(bytes32 flightKey) {
        require(flights[flightKey].isRegistered, "Flight is not registered");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function setContractOwner(address owner) public {
        contractOwner = owner;
    }

    function getContractOwner() public view returns (address) {
        return contractOwner;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(string memory airlineName, address airlineAddress)
        external
        requireIsOperational
    {
        airlines[airlineAddress] = Airline({
            airlineName: airlineName,
            airlineAddress: airlineAddress,
            isRegistered: true,
            isFunded: false
        });
        emit AirlineRegistered(airlineAddress);
    }

    function registerFlight(
        string memory flightName,
        address airlineAddress,
        uint256 timestamp
    ) external requireIsOperational {
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp);
        flights[flightKey] = Flight({
            flightName: flightName,
            isRegistered: true,
            statusCode: 0,
            updatedTimestamp: timestamp,
            airline: airlineAddress
        });
        emit FlightRegistered(flightName, airlineAddress);
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy(
        address passengerAddress,
        bytes32 flightKey,
        uint256 amount
    ) external payable requireIsOperational {
        if (!passengers[passengerAddress].isRegistered) {
            passengers[passengerAddress] = Passenger({
                passengerAddress: passengerAddress,
                isRegistered: true,
                balance: 0
            });
        }
        insurances[flightKey].push(
            Insurance({
                passenger: passengerAddress,
                amount: amount,
                isCredited: false
            })
        );
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(bytes32 flightKey) external requireIsOperational {
        for (uint256 i = 0; i < insurances[flightKey].length; i++) {
            insurances[flightKey][i].isCredited = true;
            emit InsuranceCredited(
                insurances[flightKey][i].passenger,
                flights[flightKey].flightName,
                flights[flightKey].airline,
                insurances[flightKey][i].amount.mul(3).div(2)
            );
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(address passengerAddress, bytes32 flightKey)
        external
        payable
        requireIsOperational
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < insurances[flightKey].length; i++) {
            if (insurances[flightKey][i].passenger == passengerAddress) {
                amount = insurances[flightKey][i].amount.mul(3).div(2);
                passengers[passengerAddress].balance = passengers[
                    passengerAddress
                ].balance.add(amount);
                emit PassengerWithdrawn(
                    passengerAddress,
                    flights[flightKey].flightName,
                    flights[flightKey].airline,
                    amount
                );
            }
        }
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund(address airlineAddress)
        external
        payable
        requireIsOperational
        requireAirlineRegistered(airlineAddress)
    {
        airlines[airlineAddress].isFunded = true;
        emit AirlineFunded(airlineAddress);
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    fallback() external payable {}

    receive() external payable {}
}
