// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StableSwap, IERC20 } from "src/StableSwap.sol";
import { Token } from "src/Token.sol";

contract SwapTest is PRBTest, StdCheats {
    uint256 public constant N = 2;

    StableSwap public stableSwap;

    Token public dai;
    Token public usdt;

    address[N] public TOKENS = [address(0), address(0)];

    function setUp() public virtual {
        dai = new Token("DAI", "DAI", 18);
        usdt = new Token("USDT", "USDT", 6);

        TOKENS[0] = address(dai);
        TOKENS[1] = address(usdt);

        stableSwap = new StableSwap(TOKENS);

        // mint some tokens to address(this)
        // dai -> 998,000
        dai.mint(address(this), 998_000e18);
        // usdt -> 1,000,000
        usdt.mint(address(this), 1_000_000e6);

        uint256[N] memory amounts = [uint256(998_000e18), uint256(1_000_000e6)];
        IERC20(TOKENS[0]).approve(address(stableSwap), type(uint256).max);
        IERC20(TOKENS[1]).approve(address(stableSwap), type(uint256).max);
        stableSwap.addLiquidity(amounts, 0);

        // mint some tokens to address(this)
        dai.mint(address(this), 10_000e18);
    }

    function swap(uint256 i, uint256 j, uint256 amount) public {
        address[N] memory tokens = TOKENS;

        uint256 bal = IERC20(tokens[i]).balanceOf(address(this));
        require(amount <= bal, "INVALID_AMOUNT");

        IERC20(tokens[i]).approve(address(stableSwap), amount);

        stableSwap.swap(i, j, amount, 1);
    }

    function testSwap() public {
        address[N] memory tokens = TOKENS;

        uint256 daiBalInitial = IERC20(tokens[0]).balanceOf(address(this));
        uint256 usdtBalInitial = IERC20(tokens[1]).balanceOf(address(this));
        console2.log("daiBalInitial: ", daiBalInitial);
        console2.log("usdtBalInitial: ", usdtBalInitial);

        assertEq(daiBalInitial, 10_000e18);
        assertEq(usdtBalInitial, 0);

        // swap 10,000 dai
        swap(0, 1, 10_000e18);

        uint256 daiBalAfter = IERC20(tokens[0]).balanceOf(address(this));
        uint256 usdtBalAfter = IERC20(tokens[1]).balanceOf(address(this));
        console2.log("daiBalAfter: ", daiBalAfter);
        console2.log("usdtBalAfter: ", usdtBalAfter);

        assertEq(daiBalAfter, 0);
        assertEq(usdtBalAfter, 9_999_959_976); // 9999.959976 usdt (no fee)
    }
}
