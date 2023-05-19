// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./FundoorProject.sol";

contract FundoorContributionRouter {
    function contribute(address _projectAddress, IERC20 _currency, uint256 _amount) external returns (bool) {
        // transfer token
        _currency.transferFrom(msg.sender, _projectAddress, _amount);
        // confirm contribution function is executed
        FundoorProject project = FundoorProject(_projectAddress);
        return project.contribute(msg.sender, _currency, _amount);
    }
}