// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract dNamesDNS is TimelockController {
    struct Domain {
        address owner;
        string hashAddress;
    }

    struct TLD {
        address creator;
        mapping(string => bool) domains;
    }

    mapping(string => Domain) public domains;
    mapping(string => TLD) public tlds;

    uint256 public registrationFee;
    address public daoAddress;
    address public oracleAddress;

    event DomainRegistered(string domainName, address owner, string hashAddress);
    event TLDRegistered(string tldName, address creator);

    constructor(uint256 fee, address dao, address oracle) {
        registrationFee = fee;
        daoAddress = dao;
        oracleAddress = oracle;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only the DAO contract can call this function.");
        _;
    }

    function registerDomain(string memory domainName) external payable {
        require(!isDomainRegistered(domainName), "Domain is already registered.");
        require(msg.value >= registrationFee, "Insufficient registration fee.");

        string memory hashAddress = IDHTOracle(oracleAddress).getDataFromDHT(domainName);

        domains[domainName] = Domain(msg.sender, hashAddress);

        emit DomainRegistered(domainName, msg.sender, hashAddress);

        payable(daoAddress).transfer(msg.value);
    }

    function registerTLD(string memory tldName) external payable {
        require(!isTLDRegistered(tldName), "TLD is already registered.");
        require(msg.value >= registrationFee, "Insufficient registration fee.");

        tlds[tldName] = TLD(msg.sender);

        emit TLDRegistered(tldName, msg.sender);

        payable(daoAddress).transfer(msg.value);
    }

    function isDomainRegistered(string memory domainName) public view returns (bool) {
        return domains[domainName].owner != address(0);
    }

    function isTLDRegistered(string memory tldName) public view returns (bool) {
        return tlds[tldName].creator != address(0);
    }

    function setRegistrationFee(uint256 fee) external onlyDAO {
        registrationFee = fee;
    }

    function setOracleAddress(address oracle) external onlyDAO {
        oracleAddress = oracle;
    }
}