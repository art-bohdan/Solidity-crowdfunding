// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Campaign.sol";

contract LowkickStarter {
	struct LowkickCampaign {
		Campaign targetContract;
		bool claimed;
	}

	mapping(uint256 => LowkickCampaign) public campaigns;
	uint256 private currentCompaign;
	address owner;
	uint256 constant MAX_DURATION = 30 days;

	event CampaignStarted(uint256 _id, uint256 _endsAt, uint256 goal, address organizer);

	function start(uint256 _goal, uint256 _endsAt) external {
		require(_goal > 0, "");
		require(_endsAt <= block.timestamp + MAX_DURATION && _endsAt > block.timestamp, "");
		currentCompaign++;
		Campaign newCampaign = new Campaign(currentCompaign, _endsAt, _goal, msg.sender);

		campaigns[currentCompaign] = LowkickCampaign({ targetContract: newCampaign, claimed: false });

		emit CampaignStarted(currentCompaign, _endsAt, _goal, msg.sender);
	}

	function onClaimed(uint256 id) external {
		LowkickCampaign storage targetCompaign = campaigns[id];
		require(msg.sender == address(targetCompaign.targetContract), "");

		targetCompaign.claimed = true;
	}
}
