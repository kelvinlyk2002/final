// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import remix libraries
import "remix_tests.sol"; 
import "remix_accounts.sol";

// import openZepplin libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import projects
import {FundoorLib} from "../contracts/FundoorLib.sol";
import "../contracts/FundoorProjectFactory.sol";
import "../contracts/FundoorContributionRouter.sol";
import "../contracts/FundoorController.sol";
import "../contracts/FundoorProject.sol";
import "../contracts/FundoorProjectOversight.sol";

contract Token1 is ERC20 {
    constructor() ERC20("Token1", "TK1") {
        _mint(msg.sender, 10000);
    }
}

contract Token2 is ERC20 {
    constructor() ERC20("Token2", "TK2") {
        _mint(msg.sender, 10000);
    }
}

contract FundoorProjectTest is ERC1155Holder {
    FundoorProjectFactory private factory;
    FundoorContributionRouter private router;
    FundoorController private controller;
    ERC20 private token1;
    ERC20 private token2;
    uint256 private token1currencyId;
    uint256 private token2currencyId;

    function beforeAll() public {
        // deploy test tokens 
        token1 = new Token1();
        token1currencyId = uint256(uint160(address(token1)));
        
        token2 = new Token2();
        token2currencyId = uint256(uint160(address(token2)));

        // deploy and approve router
        router = new FundoorContributionRouter();

        // approve router
        token1.approve(address(router), 10000);
        token2.approve(address(router), 10000);
        
        // deploy controller
        controller = new FundoorController();
        // deploy factory
        factory = new FundoorProjectFactory();
    }

    function contributeToProject(address projectAddress, IERC20 token, uint256 testingContributionAmount) private {
        uint256 tokenCurrencyId = uint256(uint160(address(token)));
        uint256 projectBalanceBefore = token.balanceOf(projectAddress);
        uint256 contributorBalanceBefore = token.balanceOf(address(this));
        FundoorProject project = FundoorProject(projectAddress);
        uint256 contributorNFTBalanceBefore = project.balanceOf(address(this), tokenCurrencyId);
        Assert.ok(router.contribute(projectAddress, token, testingContributionAmount), "Contribution not implemented correctly");
        
        uint256 projectBalanceAfter = token.balanceOf(projectAddress);
        uint256 contributorBalanceAfter = token.balanceOf(address(this));
        
        // confirm token has been transferred to the project
        Assert.equal(projectBalanceAfter - projectBalanceBefore, testingContributionAmount, "token not transferred correctly");
        Assert.equal(contributorBalanceBefore - contributorBalanceAfter, testingContributionAmount, "token not transferred correctly");

        // confirm an NFT receipt is received by the contributor
        Assert.equal(project.balanceOf(address(this), tokenCurrencyId), contributorNFTBalanceBefore + testingContributionAmount, "NFT receipt not transferred correctly");
    }

    function initiateProject(IERC20 currency, bool communityOversight, uint256 releaseEpoch) private returns (FundoorProject, address) {
        bool success = factory.initiateProject(IERC20(currency), address(controller), address(router), communityOversight, releaseEpoch);
        Assert.ok(success, "");
        address[] memory projects = factory.getProjects();
        address projectAddress = projects[projects.length - 1];
        FundoorProject project = FundoorProject(projectAddress);
        return (project, projectAddress);
    }

    // Test 3 - test withdrawal oversight
    function testVotableProjectWithdrawal() public {
        (FundoorProject project, address projectAddress) = initiateProject(IERC20(token1), true, block.timestamp);
        FundoorProjectOversight overseer = FundoorProjectOversight(project.getOverseerAddress());
        contributeToProject(projectAddress, token1, 100);

        // test a - withdrawal should not work before any community approval
        try controller.withdrawProjectBalance(projectAddress, token1, 100, false) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "Premature withdrawal caught");
            // funds should remain with the project
            Assert.equal(token1.balanceOf(projectAddress), 100, "Funds left unexpectedly");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test b - over-request should fail
        try overseer.requestWithdrawalApproval(token1, 120) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "Over request caught");
        } catch {
            Assert.ok(false, "Other error");
        }
        
        // test c - request 99 should pass
        Assert.ok(overseer.requestWithdrawalApproval(token1, 99), "Request not implemented correctly");

        // test d - repeated request should fail, even total is less than or equal to project holding
        try overseer.requestWithdrawalApproval(token1, 1) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "Double request caught");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test e - approval attempt should fail before voting deadline (default 1 week)
        try overseer.approveWithdrawal(token1, 99) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "premature approval caught");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test f - unobjected withdrawal proposal should lapse and withdrawal should be allowed
        // admin shorten voting time
        uint256 proposalId = overseer.getProposalNonce() - 1;
        Assert.ok(controller.setProjectProposalDeadline(projectAddress, proposalId, block.timestamp), "Deadline unable to reset");
        // over approve should fail
        try overseer.approveWithdrawal(token1, 100) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "over approval caught");
        } catch {
            Assert.ok(false, "Other error");
        }
        // correct approve withdrawal should pass
        Assert.ok(overseer.approveWithdrawal(token1, 99), "ApproveWithdrawal not implemented correctly");

        // execute first partial withdrawal
        uint256 beforeWithdrawal = token1.balanceOf(address(this));
        Assert.ok(controller.withdrawProjectBalance(projectAddress, token1, 80, false), "");
        // check balance // contributed 100, approved 99, withdrawn 80
        Assert.equal(token1.balanceOf(projectAddress), 20, "withdrawal not processed correctly");
        Assert.equal(token1.balanceOf(address(this)), beforeWithdrawal + 80, "withdrawal not processed correctly");

        // execute remaining withdrawal
        Assert.ok(controller.withdrawProjectBalance(projectAddress, token1, 19, false), "");
        // check balance // contributed 100, approved 99, withdrawn 99
        Assert.equal(token1.balanceOf(projectAddress), 1, "withdrawal not processed correctly");
        Assert.equal(token1.balanceOf(address(this)), beforeWithdrawal + 99, "withdrawal not processed correctly");

        // test g - objected withdrawal should not be processed
        // add new currency for fresh test
        Assert.ok(controller.addProjectCurrency(projectAddress, IERC20(token2)), "");
        // contribute token2
        contributeToProject(projectAddress, token2, 100);
        Assert.ok(overseer.requestWithdrawalApproval(token2, 99), "Request not implemented correctly");

        // authorize NFT to be transferred
        project.setApprovalForAll(address(overseer), true);
        // deposit NFT to vote
        Assert.ok(overseer.depositNFT(token2, 55), "Deposit NFT not implemented correctly");
        // check balance
        Assert.equal(project.balanceOf(address(overseer), token2currencyId), 55, "NFT not transferred");
        Assert.equal(project.balanceOf(address(this), token2currencyId), 45, "NFT not transferred");
        // refresh proposalId
        proposalId = overseer.getProposalNonce() - 1;
        // check voting power
        Assert.equal(overseer.getVoteWeight(address(this), proposalId), 55, "Voting weight incorrect");
        Assert.equal(overseer.getVoteWeight(address(this), proposalId - 1), 0, "Wrong proposal voting weight incorrect");

        // vote objection on token2 withdrawal
        Assert.ok(overseer.vote(proposalId, true), "Voting not implemented correctly");
        // double voting should fail
        try overseer.vote(proposalId, false) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "Double voting caught");
        } catch {
            Assert.ok(false, "Other error");
        }

        // admin shorten voting period
        Assert.ok(controller.setProjectProposalDeadline(projectAddress, proposalId, block.timestamp), "Shortening unsuccessful");

        // attempt approval over objection should fail
        try overseer.approveWithdrawal(token2, 99) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "over approval caught");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test h - Approval below or equal objection should pass
        Assert.ok(overseer.approveWithdrawal(token2, 44), "approval unsuccessful");
        // withdrawal
        Assert.ok(controller.withdrawProjectBalance(projectAddress, token2, 44, false), "withdrawal unsuccessful");
        Assert.equal(token2.balanceOf(address(this)), 9944, "withdrawal have not left project");
        Assert.equal(token2.balanceOf(projectAddress), 56, "withdrawal have not left project");
    }
}