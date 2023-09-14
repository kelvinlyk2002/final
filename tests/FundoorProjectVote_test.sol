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

    // Test 4 - test community voting
    function testVotableProjectCommunityActions() public {
        // initiate project
        (FundoorProject project, address projectAddress) = initiateProject(IERC20(token1), true, block.timestamp);
        FundoorProjectOversight overseer = FundoorProjectOversight(project.getOverseerAddress());
        // contribute and deposit for voting
        contributeToProject(projectAddress, token1, 100);
        project.setApprovalForAll(address(overseer), true);
        Assert.ok(overseer.depositNFT(token1, 80), "Deposit NFT not implemented correctly");
        
        // test a - quorum too low should be rejected
        try overseer.propose(1, token1, 1, block.timestamp + 302400) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "quorum too low caught");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test b - deadline too early should be rejected
        try overseer.propose(1, token1, 25, block.timestamp + 1) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "deadline too early caught");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test c - proper proposal should be accepted
        Assert.ok(overseer.propose(1, token1, 25, block.timestamp + 302400), "Propose implemented incorrectly");
        uint256 blockProposalId = overseer.getProposalNonce() - 1;

        // test d - withdrawal should still be available, if requested and not objected
        // request withdrawal approval
        Assert.ok(overseer.requestWithdrawalApproval(token1, 75), "Request error");
        // shorten time
        uint256 withdrawalProposalId = overseer.getProposalNonce() - 1;
        Assert.ok(controller.setProjectProposalDeadline(projectAddress, withdrawalProposalId, block.timestamp), "unable to admin shorten proposal time");
        // approval withdrawal
        Assert.ok(overseer.approveWithdrawal(token1, 75), "Approval error");
        // withdraw
        Assert.ok(controller.withdrawProjectBalance(projectAddress, token1, 75, false), "Withdrawal error");

        // test e - project should be blocked after passing of deadline (an execution action required)
        // vote
        Assert.ok(overseer.vote(blockProposalId, true), "voting error");
        // shorten time
        Assert.ok(controller.setProjectProposalDeadline(projectAddress, blockProposalId, block.timestamp), "unable to admin shorten proposal time");
        // execute
        Assert.ok(overseer.execute(blockProposalId), "execution error");
        // new contribution should be blocked
        try router.contribute(projectAddress, token1, 100) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "contribution blocked");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test f - admin should be able to unblock a project
        Assert.ok(controller.unblockProject(projectAddress), "admin unblock unsuccessful");
        // test contribution
        contributeToProject(projectAddress, token1, 100);
        
        // test g - admin should be able to block a project
        Assert.ok(controller.blockProject(projectAddress), "admin unblock unsuccessful");
        // contribution should fail
        try router.contribute(projectAddress, token1, 100) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "contribution blocked");
        } catch {
            Assert.ok(false, "Other error");
        }

        // test h - community should be able to propose unblock
        Assert.ok(overseer.propose(2, token1, 25, block.timestamp + 302400), "unblock not implemented correctly");
        // check vote weight - should equal to deposited NFT
        uint256 unblockProposalId = overseer.getProposalNonce() - 1;
        Assert.equal(overseer.getVoteWeight(address(this), unblockProposalId), 80, "vote weight incorrect");
        // vote
        Assert.ok(overseer.vote(unblockProposalId, true), "vote error");
        // admin shorten time
        Assert.ok(controller.setProjectProposalDeadline(projectAddress, unblockProposalId, block.timestamp), "deadline update error");
        // execute
        Assert.ok(overseer.execute(unblockProposalId), "execution error");
        // should be able to contribute
        contributeToProject(projectAddress, token1, 100);

        // test i - community should be able to request refund
        // propose
        Assert.ok(overseer.propose(3, token1, 25, block.timestamp + 302400), "refund not implemented correctly");
        // check vote weight - should equal to deposited NFT
        uint256 refundProposalId = overseer.getProposalNonce() - 1;
        Assert.equal(overseer.getVoteWeight(address(this), unblockProposalId), 80, "vote weight incorrect");
        // vote
        Assert.ok(overseer.vote(refundProposalId, true), "refund voting error");
        // admin shorten time
        Assert.ok(controller.setProjectProposalDeadline(projectAddress, refundProposalId, block.timestamp), "deadline update error");
        // execute         
        Assert.ok(overseer.execute(refundProposalId), "execution error");
        // redeem voting NFT
        uint256 balanceBeforeRedeem = project.balanceOf(address(this), token1currencyId);
        Assert.ok(overseer.redeemNFT(token1, 80), "NFT not redeemed");
        Assert.equal(balanceBeforeRedeem + 80, project.balanceOf(address(this), token1currencyId), "NFT not redeemed");
        // claim available refund
        Assert.ok(project.claimRefund(token1, project.balanceOf(address(this), token1currencyId)), "unclaimable");
        
        // token balance should be 0
        Assert.equal(token1.balanceOf(projectAddress), 0, "not fully refunded");
    }
}