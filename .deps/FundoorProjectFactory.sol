// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./FundoorProject.sol";

contract FundoorProjectFactory {
    // data storage
    address[] private projects;

    // initiate a new project
    function initiateProject(IERC20 _currency, address _controller, address _router, bool _communityOversight, bool _hasCommunityApprovalLimit, uint256 _releaseEpoch) 
    public returns (bool) {
        FundoorProject newProject = new FundoorProject(
                                        msg.sender,
                                        _currency,
                                        _controller,
                                        _router,
                                        _communityOversight,
                                        _hasCommunityApprovalLimit,
                                        _releaseEpoch
                                        );
        projects.push(address(newProject));
        return true;
    }

    function getProjects() external view returns (address[] memory) {
        return projects;
    }
}