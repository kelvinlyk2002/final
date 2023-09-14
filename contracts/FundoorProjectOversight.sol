// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { FundoorLib } from "./FundoorLib.sol";
import "./FundoorProject.sol";

contract FundoorProjectOversight is ERC1155Holder {
    FundoorProject private project;
    enum Proposal{ OBJECTION, BLOCK, UNBLOCK, REFUND }
    uint256 private proposalNonce;

    // veNFT
    mapping(address => mapping(uint256 => uint256)) private voters;
    mapping(address => mapping(uint256 => uint256)) private voterEarliestRedeemTimestamp;

    uint256[] private proposalIds;
    mapping(uint256 => IERC20) private proposalCurrency;
    mapping(uint256 => uint256) private proposalDeadline;
    mapping(uint256 => bool) private proposalExecuted;
    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => uint256) private proposalTimestamp;

    
    mapping(uint256 => mapping(bool => uint256)) private votes;
    mapping(uint256 => mapping(address => bool)) private voted;
    mapping(uint256 => uint8) private quorumPercentage;
    
    uint256 private withdrawalVotingPeriod = 604800;
    uint256 private votingPeriod = withdrawalVotingPeriod / 2;

    mapping(IERC20 => uint256) private withdrawalProposalAmount;
    mapping(IERC20 => uint256) private withdrawalObjectionAmount;
    mapping(IERC20 => uint256) private withdrawalApprovedAmount;
    uint256 private withdrawalObjectionProposalId;
    bool private withdrawalProposed;

    event Proposed(uint256 proposalNonce);


    constructor(address _projectAddress) {
        project = FundoorProject(_projectAddress);
    }

    modifier onlyActiveProject() {
        require(!project.getProjectShutdown(), "Withdrawn project cannot be actioned");
        _;
    }

    modifier onlyHolder(IERC20 _currency) {
        uint256 currencyId = uint256(uint160(address(_currency)));
        require(project.balanceOf(msg.sender, currencyId) > 0, "Holder only");
        _;
    }

    modifier onlyProjectOwner() {
        require(msg.sender == project.getProjectOwner(), "project owner only");
        _;
    }

    modifier onlyProject() {
        require(msg.sender == address(project), "called by project contract only");
        _;
    }

    function getProposalTypeByIndex(uint8 _index) public pure returns (Proposal) {
        require(_index >= 0 && _index < 4, "Index out of range");
        return Proposal(_index);
    }

    function depositNFT(IERC20 _currency, uint256 _amount) external onlyHolder(_currency) returns (bool) {
        // transfer NFTs from voter to this contract
        uint256 currencyId = uint256(uint160(address(_currency)));
        project.safeTransferFrom(msg.sender, address(this), currencyId, _amount, "");
        // add holder to voter's registry
        voters[msg.sender][currencyId] += _amount;
        return true;
    }

    function getDepositedWeight(IERC20 _currency, address _address) external view returns (uint256) {
        uint256 currencyId = uint256(uint160(address(_currency)));
        return voters[_address][currencyId]; 
    }

    function getEarliestRedeemTimestamp(IERC20 _currency, address _address) external view returns (uint256) {
        uint256 currencyId = uint256(uint160(address(_currency)));
        return voterEarliestRedeemTimestamp[_address][currencyId]; 
    }

    function redeemNFT(IERC20 _currency, uint256 _amount) external returns (bool) {
        uint256 currencyId = uint256(uint160(address(_currency)));
        // check if any hold of recent voting if project is not shutdown
        if(!project.getProjectShutdown()) {
            require(block.timestamp >= voterEarliestRedeemTimestamp[msg.sender][currencyId], "too early to redeem");
        }
        // transfer NFTs from this contract to voter
        project.safeTransferFrom(address(this), msg.sender, currencyId, _amount, "");
        // add holder to voter's registry
        voters[msg.sender][currencyId] -= _amount;
        return true;
    }

    function propose(uint8 _type, IERC20 _currency, uint8 _quorumPercentage, uint256 _deadline) public onlyActiveProject returns (bool) {
        // restrict quorum paramter
        require(_quorumPercentage <= 100, "Quorum will never be met.");     

        if(getProposalTypeByIndex(_type) != Proposal.OBJECTION) {
            // minimum 25% of lifetime donation required as quorum for proposal other than to object withdrawal
            require(_quorumPercentage >= 25, "Quorum should be at least 25%.");
            // deadline should be after votingPeriod parameter
            require(_deadline >= block.timestamp + votingPeriod, "Deadline must be after votingPeriod from now.");
        } else {
            // deadline should be after withdrawalVotingPeriod parameter
            require(_deadline >= block.timestamp + withdrawalVotingPeriod, "Deadline must be after withdrawalVotingPeriod from now.");
            // register withdrawal objection proposal id
            withdrawalObjectionProposalId = proposalNonce;
        }

        // register proposal
        proposalIds.push(proposalNonce);
        proposals[proposalNonce] = getProposalTypeByIndex(_type);
        proposalCurrency[proposalNonce] = _currency;
        proposalDeadline[proposalNonce] = _deadline;
        proposalTimestamp[proposalNonce] = block.timestamp;
        quorumPercentage[proposalNonce] = _quorumPercentage;

        // increment nonce after registering
        emit Proposed(proposalNonce);
        proposalNonce++;
        return true;
    }

    function getVoteWeight(address _address, uint256 _proposalId) external view returns (uint256) {
        uint256 currencyId = uint256(uint160(address(proposalCurrency[_proposalId])));
        return voters[_address][currencyId];
    }

    function vote(uint256 _proposalId, bool _vote) external onlyActiveProject returns (bool) {
        // msg sender voting weight
        uint256 currencyId = uint256(uint160(address(proposalCurrency[_proposalId])));
        uint256 voteWeight = voters[msg.sender][currencyId];
        require(voteWeight != 0, "Voter only.");

        // voted?
        require(!voted[_proposalId][msg.sender], "Address had voted.");

        // voting period
        require(block.timestamp <= proposalDeadline[_proposalId], "Voting deadline has past.");

        // update earliest redeemable time to the later of existing deadline or deadline of this proposal
        uint256 currentWithdrawableTime = voterEarliestRedeemTimestamp[msg.sender][currencyId];
        if (currentWithdrawableTime < proposalDeadline[_proposalId]){
            voterEarliestRedeemTimestamp[msg.sender][currencyId] = proposalDeadline[_proposalId];
        }

        // register votes
        if (proposals[_proposalId] == Proposal.OBJECTION && _vote) {
            withdrawalObjectionAmount[proposalCurrency[_proposalId]] += voteWeight;
        } else {
            votes[_proposalId][_vote] += voteWeight;
        }
        voted[_proposalId][msg.sender] = true;
        return true;
    }

    function getYayWeight(uint256 _proposalId) public view returns (uint256) {
        return votes[_proposalId][true];
    }

    function getNayWeight(uint256 _proposalId) public view returns (uint256) {
        return votes[_proposalId][false];
    }

    function getQuromWeight(uint256 _proposalId) public view returns (uint256) {
        uint256 currencyId = uint256(uint160(address(proposalCurrency[_proposalId])));
        uint256 total = project.getProjectLifetimeContribution(currencyId);
        return total * quorumPercentage[_proposalId] / 100;
    }

    function isExecutable(uint256 _proposalId) public view returns (bool) {
        if(proposals[_proposalId] == Proposal.OBJECTION) {
            return false;
        }
        if(block.timestamp < proposalDeadline[_proposalId]) {
            return false;
        }
        uint256 yayWeight = getYayWeight(_proposalId);
        uint256 nayWeight = getNayWeight(_proposalId);
        if(yayWeight <= nayWeight) {
            return false;
        }
        uint256 quorumWeight = getQuromWeight(_proposalId);
        if(yayWeight < quorumWeight) {
            return false;
        }
        if(proposalExecuted[_proposalId]){
            return false;
        }
        return true;
    }

    function execute(uint256 _proposalId) external onlyActiveProject returns (bool) {
        // only execute blocking, unblocking, and refund
        require(proposals[_proposalId] != Proposal.OBJECTION, "Objection proposal is not executable");

        // check if voting period has past
        require(block.timestamp >= proposalDeadline[_proposalId], "Voting deadline hasn't past.");

        // check if yay votes > nay votes
        uint256 yayWeight = getYayWeight(_proposalId);
        uint256 nayWeight = getNayWeight(_proposalId);
        require(yayWeight > nayWeight, "Majority not met");

        // check if yay votes achieved quorum
        uint256 quorumWeight = getQuromWeight(_proposalId);
        require(yayWeight >= quorumWeight, "Quorum not met");
        
        // check if project has already been executed
        require(!proposalExecuted[_proposalId], "Proposal has been executed");

        // conditions are met
        if(proposals[_proposalId] == Proposal.BLOCK) {
            // block project
            assert(project.communityBlockProject());
        } else if (proposals[_proposalId] == Proposal.UNBLOCK) {
            // unblock project
            assert(project.communityUnblockProject());
        } else if (proposals[_proposalId] == Proposal.REFUND) {
            // refund proposed refund currency
            assert(project.communityRefundProject(proposalCurrency[_proposalId]));
            // refunded project should be shutdown
            assert(project.overseerShutdownProject());
        } else {
            revert("Error in proposal type");
        }
        // register execution
        proposalExecuted[_proposalId] = true;
        return true;
    }

    // admin change the deadline of a proposal
    function setProposalDeadline(uint256 _proposalId, uint256 _newValue) external onlyProject returns (bool) {
        proposalDeadline[_proposalId] = _newValue;
        return true;
    }

    function getProposalNonce() external view returns (uint256) {
        return proposalNonce;
    }

    function getProposalCurrency(uint256 _proposalId) external view returns (IERC20) {
        return proposalCurrency[_proposalId];
    }

    function getProposalDeadline(uint256 _proposalId) external view returns (uint256) {
        return proposalDeadline[_proposalId];
    }

    function getProposalExecuted(uint256 _proposalId) external view returns (bool) {
        return proposalExecuted[_proposalId];
    }

    function getProposalType(uint256 _proposalId) external view returns (Proposal) {
        return proposals[_proposalId];
    }

    function requestWithdrawalApproval(IERC20 _currency, uint256 _amount) external onlyActiveProject onlyProjectOwner returns (bool) {
        require(!withdrawalProposed, "Proposal already in place");
        require(_amount <= _currency.balanceOf(address(project)), "Cannot approve more than current ownership");
        withdrawalProposalAmount[_currency] = _amount;
        propose(0, _currency, 0, block.timestamp + withdrawalVotingPeriod);
        withdrawalProposed = true;
        return true;
    }

    function abandonWithdrawal(IERC20 _currency) external onlyProjectOwner returns (bool) {
        require(withdrawalProposed, "No proposal or allowance exhausted");
        return resetWithdrawalAmount(_currency);
    }

    function approveWithdrawal(IERC20 _currency, uint256 _amount) external onlyActiveProject onlyProjectOwner returns (bool) {
        require(withdrawalProposed, "No proposal or allowance exhausted");
        require(proposalDeadline[withdrawalObjectionProposalId] <= block.timestamp, "Voting period has not passed");
        // limit withdrawable amount
        require(_amount <= withdrawalProposalAmount[_currency] - withdrawalObjectionAmount[_currency], "overauthorisation");
        
        // move withdrawable amount to Approved
        withdrawalProposalAmount[_currency] -= _amount;
        withdrawalApprovedAmount[_currency] += _amount;
        
        // check remaining amount
        if(withdrawalProposalAmount[_currency] == 0){
            // allowance exhausted
            withdrawalProposed = false;
        }
        return true;
    }

    function completeWithdrawal(IERC20 _currency, uint256 _amount) external onlyProject returns (bool) {
        withdrawalApprovedAmount[_currency] -= _amount;
        return resetWithdrawalAmount(_currency);
    }

    function getProposedWithdrawalAmount(IERC20 _currency) external view returns (uint256) {
        return withdrawalProposalAmount[_currency];
    }

    function getObjectedWithdrawalAmount(IERC20 _currency) external view returns (uint256) {
        return withdrawalObjectionAmount[_currency];
    }

    function getApprovedWithdrawalAmount(IERC20 _currency) external view returns (uint256) {
        return withdrawalApprovedAmount[_currency];
    }

    function resetWithdrawalAmount(IERC20 _currency) internal returns (bool) {
        withdrawalProposalAmount[_currency] = 0;
        withdrawalObjectionAmount[_currency] = 0;
        // approved must be zero if abandoned
        withdrawalProposed = false;
        return true;
    }

    function getWithdrawalProposed() external view returns (bool) {
        return withdrawalProposed;
    }

    function getLastWithdrawalProposalId() external view returns (uint256) {
        return withdrawalObjectionProposalId;
    }
}