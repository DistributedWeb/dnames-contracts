// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governance.sol";

contract dNamesDAO is Governance {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        bool executed;
        bool isBlockProposal;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter;
    mapping(address => uint256) public votes;

    address public dnsAddress;
    address public oracleAddress;
    mapping(string => bool) public blockedDomains;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 voteCount);
    event ProposalExecuted(uint256 indexed proposalId);
    event DomainBlocked(string domainName);

    constructor(address dns) {
        dnsAddress = dns;
    }

    modifier onlyDNS() {
        require(msg.sender == dnsAddress, "Only the dNamesDNS contract can call this function.");
        _;
    }

    function createProposal(string memory description, bool isBlockProposal) external onlyDNS returns (uint256) {
        uint256 proposalId = _createProposal();
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            voteCount: 0,
            executed: false,
            isBlockProposal: isBlockProposal
        });

        emit ProposalCreated(proposalId, msg.sender);

        return proposalId;
    }

    function vote(uint256 proposalId, uint256 voteCount) external onlyDNS {
        require(!proposals[proposalId].executed, "Proposal has already been executed.");

        votes[msg.sender] = voteCount;
        proposals[proposalId].voteCount += voteCount;

        emit Voted(proposalId, msg.sender, voteCount);
    }

    function executeProposal(uint256 proposalId) external onlyDNS {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed.");

        if (proposal.isBlockProposal && proposal.voteCount > totalSupply() / 2) {
            blockedDomains[proposal.description] = true;
            emit DomainBlocked(proposal.description);
        }

        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    function setOracleAddress(address oracle) external onlyDNS {
        oracleAddress = oracle;
    }
}