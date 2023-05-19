// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./FundoorProject.sol";

contract FundoorController is Ownable {
    modifier onlyProjectOwner(address _projectAddress) {
        FundoorProject project = FundoorProject(_projectAddress);
        require(project.getProjectOwner() == msg.sender, "Only owner");
        _;
    }

    // disable a project at contract level
    function deactiveProject(address _projectAddress) external onlyProjectOwner(_projectAddress) returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.deactivateProject();
    }

    // withdraw balance
    function withdrawProjectBalance(address _projectAddress, IERC20 _currency, uint256 _withdrawalAmount, bool _isShutdown) external onlyProjectOwner(_projectAddress) returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.withdrawProjectBalance(_currency, _withdrawalAmount, _isShutdown);
    }

    // transfer owner
    function transferOwner(address _projectAddress, address _newOwner) public onlyProjectOwner(_projectAddress) returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.transferOwner(_newOwner);
    }

    // add new supported currency
    function addProjectCurrency(address _projectAddress, IERC20 _currency) external onlyProjectOwner(_projectAddress) returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.addCurrency(_currency);
    }

    // admin block a project
    function blockProject(address _projectAddress) external onlyOwner returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.adminBlockProject();
    }

    // admin unblock a project
    function unblockProject(address _projectAddress) external onlyOwner returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.adminUnblockProject();
    }

    // admin refund a project
    function refundProject(address _projectAddress) external onlyOwner returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.adminRefundProject();
    }

    // admin change the release epoch
    function setProjectReleaseTime(address _projectAddress, uint256 _newValue) external onlyOwner returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.setProjectReleaseTime(_newValue);
    }

    // admin change the voting period
    function setProjectProposalDeadline(address _projectAddress, uint256 _proposalId, uint256 _newValue) external onlyOwner returns (bool) {
        FundoorProject project = FundoorProject(_projectAddress);
        return project.setProposalDeadline(_proposalId, _newValue);
    }
}