// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//todo: refund factor
//todo: community vote block

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {FundoorLib} from "./FundoorLib.sol";
import "./FundoorProjectOversight.sol";

contract FundoorProject is ERC1155, Ownable {
    address private controllerAddress;
    address private contributionRouterAddress;
    FundoorProjectOversight private overseer;

    address private projectOwner;
    IERC20[] private projectCurrencies;
    mapping(uint256 => uint256) private projectLifetimeContribution;
    mapping(IERC20 => uint256) private refundPot;
    uint256 private projectReleaseTime;
    bool private projectActive;
    bool private projectBlocked;
    bool private projectShutdown;

    event projectInitiated(address projectOwner, uint256 releaseEpoch);
    event projectCurrencyAdded(IERC20 newCurrency);
    event projectOwnerChanged(address newOwner);
    event projectActivated();
    event projectDeactivated();
    
    event Contributed(address contributor, IERC20 token, uint256 amount);
    event Withdrawn(address owner, IERC20 token, uint256 amount);
    event Refunded(address refunder, IERC20 currency, uint256 balance);
    event Blocked();
    event Unblocked();

    modifier onlyActiveProject() {
        require(projectActive, "Only active project can run this function.");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controllerAddress, "Only controller can run this function");
        _;
    }

    modifier onlyOverseer() {
        require(msg.sender == address(overseer), "Only overseer can run this function");
        _;
    }

    modifier onlyAfterTimeLock() {
        require(block.timestamp >= projectReleaseTime, "Too soon");
        _;
    }

    modifier onlyContributionRouter() {
        require(msg.sender == contributionRouterAddress, "Only contribution router can run this function");
        _;
    }

    constructor(address _projectOwner, IERC20 _currency, address _controllerAddress, address _contributionRouterAddress, bool _communityOversight, uint256 _releaseEpoch) ERC1155("") {
        controllerAddress = _controllerAddress;
        contributionRouterAddress = _contributionRouterAddress;

        if(_communityOversight) {
            overseer = new FundoorProjectOversight(address(this));
        }

        projectOwner = _projectOwner;
        projectReleaseTime = _releaseEpoch;
        emit projectInitiated(_projectOwner, _releaseEpoch);

        projectCurrencies.push(_currency);
        emit projectCurrencyAdded(_currency);

        projectActive = true;
        emit projectActivated();
    }

    function transferOwner(address _newOwner) external onlyController returns (bool) {
        projectOwner = _newOwner;
        return true;
    }

    function getProjectActive() external view returns (bool) {
        return projectActive;
    }

    function activateProject() private returns (bool) {
        require(!projectShutdown, "Unable to reactivate project that has shut down.");
        projectActive = true;
        emit projectActivated();
        return true;
    }

    function ownerDeactivateProject() external onlyController returns (bool) {
        return deactivateProject();
    }

    function deactivateProject() private returns (bool) {
        projectActive = false;
        emit projectDeactivated();
        return true;
    }

    function getProjectOwner() external view returns (address) {
        return projectOwner;
    }

    function getProjectCurrencies(uint256) external view returns (IERC20[] memory) {
        return projectCurrencies;
    }

    function addCurrency(IERC20 _newCurrency) external onlyController onlyActiveProject returns (bool) {
        projectCurrencies.push(_newCurrency);
        emit projectCurrencyAdded(_newCurrency);
        return true;
    }

    function withdrawProjectBalance(IERC20 _currency, uint256 _withdrawalAmount, bool _isShutdown) public onlyAfterTimeLock onlyController returns (bool) {
        assert(!projectBlocked); // project blocked
        uint256 balance = _currency.balanceOf(address(this));
        uint256 toWithdraw = FundoorLib.min(_withdrawalAmount, balance);
        // if community approval required
        if(address(overseer) != address(0)) {
            require(overseer.getApprovedWithdrawalAmount(_currency) > 0, "None approved");
            toWithdraw = FundoorLib.min(overseer.getApprovedWithdrawalAmount(_currency), _withdrawalAmount);
            overseer.completeWithdrawal(_currency, toWithdraw);
        }
        _currency.transfer(projectOwner, toWithdraw);
        emit Withdrawn(projectOwner, _currency, toWithdraw);

        // if shutting down
        if(_isShutdown) {
            // deactivate the project
            projectActive = false;
            projectShutdown = true;
        }

        return true;
    }

    function withdrawAll() external onlyAfterTimeLock onlyController returns (bool) {
        for(uint256 i = 0; i < projectCurrencies.length; i++) {
            assert(withdrawProjectBalance(
                projectCurrencies[i], // currency
                projectCurrencies[i].balanceOf(address(this)), // drawing max available
                i == projectCurrencies.length - 1 // shutdown if last currency
            ));
        }
        return true;
    }

    function getProjectAddress() external view returns (address) {
        return address(this);
    }

    function getProjectShutdown() external view returns (bool) {
        return projectShutdown;
    }

    function contribute(address _contributor, IERC20 _projectCurrency, uint256 _amount) external onlyActiveProject onlyContributionRouter returns (bool) {        
        uint256 currencyId = uint256(uint160(address(_projectCurrency)));
        // mint receipt nft
        _mint(_contributor, currencyId, _amount, "");
        // increment lifetime contribution
        projectLifetimeContribution[currencyId] += _amount;
        emit Contributed(_contributor, _projectCurrency, _amount);
        return true;
    }

    function getProjectLifetimeContribution(uint256 _currencyId) public view returns (uint256) {
        return projectLifetimeContribution[_currencyId];
    }

    function _blockProject() private returns (bool) {
        // block funds withdrawal
        projectBlocked = true;
        // block any new contribution
        assert(deactivateProject());
        emit Blocked();
        return true;
    }

    function _unblockProject() private returns(bool) {
        // allow funds withdrawal
        projectBlocked = false;
        // allow any new contribution
        assert(activateProject());
        emit Unblocked();
        return true;
    }

    function claimRefund(IERC20 _currency) external returns (bool) {
        // sanity check
        require(refundPot[_currency] > 0, "No funds to be refunded");
        
        // check if sender holds the related nft
        uint256 currencyId = uint256(uint160(address(_currency)));
        uint256 nftBalance = balanceOf(msg.sender, currencyId);
        require(nftBalance > 0, "No refunds owed to msg sender.");
        // calculate available refunds
        uint256 availableRefund = nftBalance * _currency.balanceOf(address(this)) / projectLifetimeContribution[currencyId];
        // transfer available refunds
        _currency.transfer(msg.sender, availableRefund);
        // burn nft
        _burn(msg.sender, currencyId, nftBalance);
        // event
        emit Refunded(msg.sender, _currency, availableRefund);
        return true;
    }

    function _refundProject(IERC20 _currency) private returns (bool) {
        // unable to refund withdrawn projects
        require(!projectShutdown, "No funds to refund for shut down projects.");
        // moving all remaining funds to the refund pot
        refundPot[_currency] = _currency.balanceOf(address(this));

        return true;
    }

    function adminBlockProject() external onlyController returns (bool) {
        return _blockProject();
    }

    function adminUnblockProject() external onlyController returns (bool) {
        return _unblockProject();
    }

    function adminRefundProject() external onlyController returns (bool) {
        for(uint256 i = 0; i < projectCurrencies.length; i++){
            assert(_refundProject(projectCurrencies[i]));
        }
        return true;
    }

    function communityBlockProject() external onlyOverseer returns (bool) {
        return _blockProject();
    }

    function communityUnblockProject() external onlyOverseer returns (bool) {
        return _unblockProject();
    }

    function communityRefundProject(IERC20 _currency) external onlyOverseer returns (bool) {
        return _refundProject(_currency);
    }

    function addressToId(IERC20 _currency) public pure returns(uint256) {
        return uint256(uint160(address(_currency)));
    }

    function getControllerAddress() public view returns(address) {
        return controllerAddress;
    }

    function getOverseerAddress() public view returns (address) {
        return address(overseer);
    }

    function getReleaseTime() public view returns (uint256) {
        return projectReleaseTime;
    }

    function setProjectReleaseTime(uint256 _newValue) external onlyController returns (bool) {
        projectReleaseTime = _newValue;
        return true;
    }

    function setProposalDeadline(uint256 _proposalId, uint256 _newValue) external onlyController returns (bool) {
        return overseer.setProposalDeadline(_proposalId, _newValue);
    }

    function overseerShutdownProject() external onlyOverseer returns (bool) {
        projectShutdown = true;
        return projectShutdown;
    }
}