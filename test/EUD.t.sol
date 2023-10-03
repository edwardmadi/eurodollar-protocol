// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: © 2023 Rhinefield Technologies Limited

pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {EUD} from "../src/EUD.sol";
import {Constants} from "./Constants.sol";

contract EUDTest is Test, Constants {
    EUD public eud;

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {
        EUD implementation = new EUD();
        ERC1967Proxy eudProxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(EUD.initialize, ())
        );
        //eud.initialize();
        eud = EUD(address(eudProxy));
        eud.grantRole(MINT_ROLE, address(this));
        eud.grantRole(BURN_ROLE, address(this));
        eud.grantRole(BLOCK_ROLE, address(this));
        eud.grantRole(PAUSE_ROLE, address(this));
        eud.grantRole(FREEZE_ROLE, address(this));
        eud.grantRole(ALLOW_ROLE, address(this));
    }

    function testInitialize() public {
        assertTrue(eud.hasRole(0x00, address(this)));
        assertEq(eud.symbol(), "EUD");
        assertEq(eud.name(), "EuroDollar");
        assertEq(eud.decimals(), 18);
    }

    function testMintEud(uint256 amount) public {
        eud.mint(address(this), amount);
        assertEq(eud.balanceOf(address(this)), amount);
    }

    function testBurnEud(uint256 amount) public {
        eud.mint(address(this), amount);
        eud.burn(address(this), amount);
        assertEq(eud.balanceOf(address(this)), 0);
    }

    function testFailMintEudNotAuthorized(address account, uint256 amount) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.mint(address(this), amount);
    }

    function testFailBurnEudNotAuthorized(address account, uint256 amount) public {
        vm.assume(account != address(this));
        eud.mint(account, amount);
        vm.prank(account);
        eud.burn(account, amount);
        assertEq(eud.balanceOf(address(this)), 0);
    }

    function testGrantMintRole(address account) public {
        eud.grantRole(MINT_ROLE, account);
        assertTrue(eud.hasRole(MINT_ROLE, account));
    }

    function testGrantBurnRole(address account) public {
        eud.grantRole(BURN_ROLE, account);
        assertTrue(eud.hasRole(BURN_ROLE, account));
    }

    function testGrantPauseRole(address account) public {
        eud.grantRole(PAUSE_ROLE, account);
        assertTrue(eud.hasRole(PAUSE_ROLE, account));
    }

    function testGrantAdminRole(address account) public {
        eud.grantRole(DEFAULT_ADMIN_ROLE, account);
        assertTrue(eud.hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    function testPause(address pauser) public {
        eud.grantRole(PAUSE_ROLE, pauser);
        vm.prank(pauser);
        eud.pause();
        assertTrue(eud.paused());
    }

    function testFailUnauthorizedGrantRoles(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function testFailUnauthorizedGrantMintRole(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.grantRole(MINT_ROLE, account);
    }

    function testFailUnauthorizedGrantBurnRole(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.grantRole(BURN_ROLE, account);
    }

    function testFailUnauthorizedGrantPauseRole(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.grantRole(PAUSE_ROLE, account);
    }

    function testFailUnauthorizedGrantFreezeRole(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.grantRole(FREEZE_ROLE, account);
    }

    function testFailUnauthorizedGrantBlocklistRole(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.grantRole(BLOCK_ROLE, account);
    }

    function testUnpause(address pauser) public {
        eud.grantRole(PAUSE_ROLE, pauser);
        vm.prank(pauser);
        eud.pause();
        assertTrue(eud.paused());
        vm.prank(pauser);
        eud.unpause();
        assertEq(eud.paused(), false);
    }

    function testFailUnathorizedPause(address pauser) public {
        vm.assume(pauser != address(this));
        vm.prank(pauser);
        eud.pause();
        assertEq(eud.paused(), false);
    }

    function testFailUnathorizedUnpause(address pauser) public {
        vm.assume(pauser != address(this));
        eud.pause();
        vm.prank(pauser);
        eud.unpause();
        assertEq(eud.paused(), false);
    }

    function testTransferEud(address account, uint256 amount) public {
        vm.assume(account != address(0));
        eud.mint(address(this), amount);
        eud.transfer(account, amount);
        assertEq(eud.balanceOf(account), amount);
        vm.prank(account);
        eud.transfer(address(this), amount);
        assertEq(eud.balanceOf(address(this)), amount);
    }

    function testAddToBlocklist(address account) public {
        eud.addToBlocklist(account);
        assertTrue(eud.blocklist(account));
    }

    function testAddManyToBlocklist(address account1, address account2, address account3) public {
        address[] memory accounts = new address[](3);
        accounts[0] = account1;
        accounts[1] = account2;
        accounts[2] = account3;
        eud.addManyToBlocklist(accounts);
        for (uint256 i = 0; i < accounts.length; i++) {
            assertTrue(eud.blocklist(accounts[i]));
        }
    }

    function testRemoveFromBlocklist(address account) public {
        eud.addToBlocklist(account);
        assertTrue(eud.blocklist(account));
        eud.removeFromBlocklist(account);
        assertTrue(!eud.blocklist(account));
    }

    function testRemoveManyFromBlocklist(address account1, address account2, address account3) public {
        address[] memory accounts = new address[](3);
        accounts[0] = account1;
        accounts[1] = account2;
        accounts[2] = account3;
        eud.addManyToBlocklist(accounts);
        for (uint256 i = 0; i < accounts.length; i++) {
            assertTrue(eud.blocklist(accounts[i]));
        }
        eud.removeManyFromBlocklist(accounts);
        for (uint256 i = 0; i < accounts.length; i++) {
            assertTrue(!eud.blocklist(accounts[i]));
        }
    }

    function testFailAddToBlocklistNotAuthorized(address account) public {
        vm.assume(account != address(this));
        vm.prank(account);
        eud.addToBlocklist(account);
        assertTrue(eud.blocklist(account));
    }

    function testFailRemoveFromBlocklistNotAuthorized(address account) public {
        vm.assume(account != address(this));
        eud.addToBlocklist(account);
        assertTrue(eud.blocklist(account));
        vm.prank(account);
        eud.removeFromBlocklist(account);
        assertTrue(!eud.blocklist(account));
    }

    function testFreeze(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(0) && account2 != address(0));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        eud.freeze(account1, account2, amount);
        assertEq(eud.balanceOf(account2), amount);
        assertEq(eud.frozenBalances(account1), amount);
    }

    function testFailUnauthorizedFreeze(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(this) && account1 != address(0));
        vm.assume(account2 != address(0));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        vm.prank(account1);
        eud.freeze(account1, account2, amount);
    }

    function testRelease(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(this) && account1 != address(0));
        vm.assume(account2 != address(0));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        eud.freeze(account1, account2, amount);
        assertEq(eud.balanceOf(account2), amount);
        assertEq(eud.frozenBalances(account1), amount);
        eud.release(account2, account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        assertEq(eud.frozenBalances(account2), 0);
    }

    function testFailUnauthorizedRelease(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(this) && account1 != address(0));
        vm.assume(account2 != address(0));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        eud.freeze(account1, account2, amount);
        assertEq(eud.balanceOf(account2), amount);
        assertEq(eud.frozenBalances(account1), amount);
        vm.prank(account1);
        eud.release(account2, account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        assertEq(eud.frozenBalances(account2), 0);
    }

    function testFailReleaseTooManyTokens(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(this) && account1 != address(0));
        vm.assume(account2 != address(0));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        eud.freeze(account1, account2, amount);
        assertEq(eud.balanceOf(account2), amount);
        assertEq(eud.frozenBalances(account1), amount);
        eud.release(account2, account1, amount + 1);
        assertEq(eud.balanceOf(account1), amount + 1);
        assertEq(eud.frozenBalances(account2), 0);
    }

    function testReclaim(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(0));
        vm.assume(account2 != address(0));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        eud.reclaim(account1, account2, amount);
        assertEq(eud.balanceOf(account2), amount);
        vm.prank(account2);
        eud.transfer(address(this), amount);
        assertEq(eud.balanceOf(address(this)), amount);
    }

    function testFailUnauthorizedReclaim(address account1, address account2, uint256 amount) public {
        vm.assume(account1 != address(0));
        vm.assume(account2 != address(this));
        eud.mint(account1, amount);
        assertEq(eud.balanceOf(account1), amount);
        vm.startPrank(account2);
        eud.reclaim(account1, account2, amount);
        assertEq(eud.balanceOf(account2), amount);
        eud.transfer(address(this), amount);
        vm.stopPrank();
        assertEq(eud.balanceOf(address(this)), amount);
    }

    function testApproveEud(address account, uint256 amount) public {
        vm.assume(account != address(0));
        eud.mint(account, amount);
        assertEq(eud.balanceOf(account), amount);
        vm.prank(account);
        eud.approve(address(this), amount);
        assertEq(eud.allowance(account, address(this)), amount);
    }

    function testIncreaseAllowance(address account, uint256 amount) public {
        vm.assume(account != address(0));
        eud.mint(account, amount);
        assertEq(eud.balanceOf(account), amount);
        vm.prank(account);
        eud.increaseAllowance(address(this), amount);
        assertEq(eud.allowance(account, address(this)), amount);
    }

    function testDecreaseAllowance(address account, uint256 amount) public {
        vm.assume(account != address(0));
        eud.mint(account, amount);
        assertEq(eud.balanceOf(account), amount);
        vm.startPrank(account);
        eud.increaseAllowance(address(this), amount);
        assertEq(eud.allowance(account, address(this)), amount);
        eud.decreaseAllowance(address(this), amount);
        vm.stopPrank();
        assertEq(eud.allowance(account, address(this)), 0);
    }

    function testPermit(uint8 privateKey, address receiver, uint256 amount, uint256 deadline) public {
        vm.assume(privateKey != 0);
        vm.assume(receiver != address(0));
        address owner = vm.addr(privateKey);
        vm.assume(owner != receiver);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    eud.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, receiver, amount, 0, deadline))
                )
            )
        );
        vm.warp(deadline);
        eud.permit(owner, receiver, amount, deadline, v, r, s);

        assertEq(eud.allowance(owner, receiver), amount);
        assertEq(eud.nonces(owner), 1);
    }

    function testFailPermitTooLate(uint8 privateKey, address receiver, uint256 amount, uint256 deadline) public {
        deadline = bound(deadline, 0, UINT256_MAX);
        vm.assume(privateKey != 0);
        vm.assume(receiver != address(0));
        address owner = vm.addr(privateKey);
        vm.assume(owner != receiver);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    eud.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, receiver, amount, 0, deadline))
                )
            )
        );
        vm.warp(deadline + 1);
        eud.permit(owner, receiver, amount, deadline, v, r, s);

        assertEq(eud.allowance(owner, receiver), amount);
        assertEq(eud.nonces(owner), 1);
    }

    function testFailUnauthorizedPermit(
        uint8 privateKey1,
        uint8 privateKey2,
        address receiver,
        uint256 amount,
        uint256 deadline
    )
        public
    {
        vm.assume(privateKey1 != 0 && privateKey2 != 0);
        vm.assume(privateKey1 != privateKey2);
        vm.assume(receiver != address(0));
        address owner = vm.addr(privateKey1);
        vm.assume(owner != receiver);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey2,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    eud.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, receiver, amount, 0, deadline))
                )
            )
        );
        vm.warp(deadline);
        eud.permit(owner, receiver, amount, deadline, v, r, s);
    }

    // This event is not reachable directly from the original implementation for some reason
    event Upgraded(address indexed implementation);

    function testAuthorizeUpgrade() public {
        EUDv2 newEud = new EUDv2();

        // The Upgraded event is one observable side-effect of a successful upgrade
        vm.expectEmit(address(eud));
        emit Upgraded(address(newEud));
        eud.upgradeToAndCall(address(newEud), abi.encodeCall(newEud.initializeV2, ()));

        assertTrue(eud.hasRole(eud.DEFAULT_ADMIN_ROLE(), address(this)));
        assertEq(eud.symbol(), "EUD");
        assertEq(eud.name(), "EuroDollar");
        assertEq(eud.decimals(), 18);
    }
}

// Dummy v2 contract
contract EUDv2 is EUD {
    function initializeV2() public reinitializer(2) {}
}
