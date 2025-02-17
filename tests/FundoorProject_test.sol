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

    function initiateProject(IERC20 _currency, bool _communityOversight, uint256 _releaseEpoch) private returns (FundoorProject, address) {
        bool success = factory.initiateProject(IERC20(_currency), address(controller), address(router), _communityOversight, _releaseEpoch);
        Assert.ok(success, "");
        address[] memory projects = factory.getProjects();
        address projectAddress = projects[projects.length - 1];
        FundoorProject project = FundoorProject(projectAddress);
        return (project, projectAddress);
    }

    // Test 1 - test a project with no withdrawal delay and no community oversight
    function testSimpleProject() public {
        // initiate a project
        (FundoorProject project, address projectAddress) = initiateProject(IERC20(token1), false, block.timestamp);

        // test a - check if the new project is correctly initiated and ready to receive
        Assert.ok(project.getProjectActive(), "");

        // test b - contribute token1
        // contribute token1
        contributeToProject(projectAddress, token1, 100);
        
        // test c - add new currency to the project
        Assert.ok(controller.addProjectCurrency(projectAddress, IERC20(token2)), "");
        // contribute token2
        contributeToProject(projectAddress, token2, 100);

        // test d - withdrawing - all erc20 should go back
        Assert.ok(controller.withdrawProjectBalance(projectAddress, token1, 100, false), "");
        Assert.ok(controller.withdrawProjectBalance(projectAddress, token2, 100, true), "");
        // no token at project address
        Assert.equal(token1.balanceOf(projectAddress), 0, "");
        Assert.equal(token2.balanceOf(projectAddress), 0, "");
        // all funds withdrawn
        Assert.equal(token1.balanceOf(address(this)), 10000, "");
        Assert.equal(token2.balanceOf(address(this)), 10000, "");
    }

    // Test 2 - test time delayed contract
    function testDelayedProject() public {
        uint256 timeToAdd = 120;
        (, address projectAddress) = initiateProject(IERC20(token1), false, block.timestamp + timeToAdd);
        contributeToProject(projectAddress, token1, 100);
        // test a - early withdrawal
        try controller.withdrawProjectBalance(projectAddress, token1, 100, false) returns (bool r) {
            Assert.equal(r, false, "Did not fail");
        } catch Error(string memory) {
            // correctly reverted
            Assert.ok(true, "Premature withdrawal caught");
        } catch {
            Assert.ok(false, "Other error");
        }
        // reset project release time to now
        Assert.ok(controller.setProjectReleaseTime(projectAddress, block.timestamp), "");
        // test b - withdraw should be successful after
        controller.withdrawProjectBalance(projectAddress, token1, 100, true);
    }
}