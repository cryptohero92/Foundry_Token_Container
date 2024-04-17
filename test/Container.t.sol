// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {Container, ContainerStatus} from "../src/Container.sol";

contract ContainerHarness is Container {
    constructor(MyToken _token, uint256 _capacity) Container(_token, _capacity) {}

    function exposed_isOverflowing(uint256 balance) external view returns(bool) {
        return _isOverflowing(balance);
    }
}

contract ContainerTest is Test {
    MyToken public token;
    Container public container;

    uint256 constant CAPACITY = 100;

    // Runs before each test
    function setUp() public {
        token = new MyToken(1000);
        container = new Container(token, CAPACITY);
    }

    // Fuzz tests for success upon minting tokens one ether or below
    function testMintOneEtherOrBelow(uint256 amountToMint) public {
        vm.assume(amountToMint <= 1 ether);

        token.mint(amountToMint, msg.sender);
        assertEq(token.balanceOf(msg.sender), amountToMint);
    }

    // Tests for negative cases of the internal _isOverflowing function
    function testIsOverflowingFalse() public {
        ContainerHarness harness = new ContainerHarness(token , CAPACITY);
        assertFalse(harness.exposed_isOverflowing(CAPACITY - 1));
        assertFalse(harness.exposed_isOverflowing(CAPACITY));
        assertFalse(harness.exposed_isOverflowing(0));
    }

    // Tests if the container is unsatisfied right after constructing
    function testInitialUnsatisfied() public {
        assertEq(token.balanceOf(address(container)), 0);
        assertTrue(container.status() == ContainerStatus.Unsatisfied);
    }

    // Tests if the container will be "full" once it reaches its capacity
    function testContainerFull() public {
        token.transfer(address(container), CAPACITY);
        container.updateStatus();

        assertEq(token.balanceOf(address(container)), CAPACITY);
        assertTrue(container.status() == ContainerStatus.Full);
    }

    // Fuzz tests for failure upon minting tokens above one ether
    function testFailMintAboveOneEther(uint256 amountToMint) public {
        vm.assume(amountToMint > 1 ether);

        token.mint(amountToMint, msg.sender);
    }
}