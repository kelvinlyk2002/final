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
import {FundoorLib} from "../.deps/FundoorLib.sol";
import "../.deps/FundoorProjectFactory.sol";
import "../.deps/FundoorContributionRouter.sol";
import "../.deps/FundoorController.sol";
import "../.deps/FundoorProject.sol";
import "../.deps/FundoorProjectOversight.sol";

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

        Assert.ok(router.contribute(projectAddress, token, testingContributionAmount), "Contribution not implemented correctly");

        uint256 projectBalanceAfter = token.balanceOf(projectAddress);
        uint256 contributorBalanceAfter = token.balanceOf(address(this));

        // confirm token has been transferred to the project
        Assert.equal(projectBalanceAfter - projectBalanceBefore, testingContributionAmount, "token not transferred correctly");
        Assert.equal(contributorBalanceBefore - contributorBalanceAfter, testingContributionAmount, "token not transferred correctly");

        // confirm an NFT receipt is received by the contributor
        FundoorProject project = FundoorProject(projectAddress);
        Assert.equal(project.balanceOf(address(this), tokenCurrencyId), testingContributionAmount, "NFT receipt not transferred correctly");
    }

    function initiateProject(IERC20 currency, bool communityOversight, uint256 releaseEpoch) private returns (FundoorProject, address) {
        bool success = factory.initiateProject(IERC20(currency), address(controller), address(router), communityOversight, releaseEpoch);
        Assert.ok(success, "");
        address[] memory projects = factory.getProjects();
        address projectAddress = projects[projects.length - 1];
        FundoorProject project = FundoorProject(projectAddress);
        return (project, projectAddress);
    }

    // Test 3 - test community oversight and voting
    function testVotableProject() public {
        (FundoorProject project, address projectAddress) = initiateProject(IERC20(token1), true, block.timestamp);
        FundoorProjectOversight overseer = FundoorProjectOversight(project.getOverseerAddress());
        contributeToProject(projectAddress, token1, 100);

        // test a - withdrawal should not work any community approval
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
        
        // test c - request 100 should pass
        Assert.ok(overseer.requestWithdrawalApproval(token1, 100), "Request not implemented correctly");

        // test d - objected withdrawal should not be processed
        // authorize NFT to be transferred
        project.setApprovalForAll(address(overseer), true);

        // deposit NFT to vote
        Assert.ok(overseer.depositNFT(token1, 55), "Deposit NFT not implemented correctly");
        // check balance
        Assert.equal(project.balanceOf(address(overseer), token1currencyId), 55, "NFT not transferred");
        Assert.equal(project.balanceOf(address(this), token1currencyId), 45, "NFT not transferred");
        // check voting power
        uint256 proposalId = overseer.getProposalNonce() - 1;
        Assert.equal(overseer.getVoteWeight(address(this), proposalId), 55, "Voting weight incorrect");
        // uint256 beforeWithdrawal = token1.balanceOf(address(this));
        // Assert.ok(controller.withdrawProjectBalance(projectAddress, token1, 10, false), "");
        // Assert.equal(token1.balanceOf(address(this)), beforeWithdrawal + 10, "");

        // // test b - community propose block
        // Assert.ok(overseer.propose(1, token1, 25, block.timestamp + 604800), "");

        // test c - withdraw when a proposal in effect


        // // reset project release time to now
        // Assert.ok(controller.setProjectReleaseTime(projectAddress, block.timestamp), "");
        // // test b - withdraw should be successful after
        // controller.withdrawProjectBalance(projectAddress, token1, 100, true);
    }
}