// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LowkickStarter.sol";

contract Campaign {
	uint256 public endsAt;
	uint256 public goal;
	uint256 public pledged;
	uint256 public id;
	address public organizer;
	LowkickStarter parent;
	bool claimed;
	mapping(address => uint256) pledges;

	event Pledged(uint256 amount, address pledger);
	event RefundPledge(uint256 amount, address pledger);

	constructor(
		uint256 _id,
		uint256 _endsAt,
		uint256 _goal,
		address _organizer
	) {
		endsAt = _endsAt;
		goal = _goal;
		organizer = _organizer;
		parent = LowkickStarter(msg.sender);
		id = _id;
	}

	function pledge() external payable {
		require(block.timestamp <= endsAt);
		require(msg.value > 0);

		pledged += msg.value;
		pledges[msg.sender] += msg.value;

		emit Pledged(msg.value, msg.sender);
	}

	function refundPledge(uint256 _amount) external payable {
		require(block.timestamp <= endsAt, "");
		require(_amount <= pledges[msg.sender], "");

		pledged -= msg.value;
		pledges[msg.sender] -= _amount;
		payable(msg.sender).transfer(_amount);

		emit RefundPledge(_amount, msg.sender);
	}

	function claim() external {
		require(block.timestamp > endsAt, "");
		require(msg.sender == organizer, "");
		require(pledged >= goal, "");
		require(!claimed, "");

		claimed = true;
		payable(organizer).transfer(pledged);

		parent.onClaimed(id);
	}

	function fullRefund() external {
		require(block.timestamp > endsAt, "");
		require(pledged < goal, "");

		uint256 refundAmount = pledges[msg.sender];
		pledges[msg.sender] = 0;
		payable(msg.sender).transfer(refundAmount);
	}
}
