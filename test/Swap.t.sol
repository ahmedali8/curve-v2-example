// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StableSwap, IERC20 } from "src/StableSwap.sol";
import { Token } from "src/Token.sol";

contract SwapTest is PRBTest, StdCheats {
    uint256 public constant N = 3;

    StableSwap public stableSwap;

    Token public dai;
    Token public usdc;
    Token public usdt;

    address[N] public TOKENS = [address(0), address(0), address(0)];

    function setUp() public virtual {
        dai = new Token("DAI", "DAI", 18);
        usdc = new Token("USDC", "USDC", 6);
        usdt = new Token("USDT", "USDT", 6);

        TOKENS[0] = address(dai);
        TOKENS[1] = address(usdc);
        TOKENS[2] = address(usdt);

        stableSwap = new StableSwap(TOKENS);

        // mint some tokens to address(this)
        // dai -> 191,922,690
        dai.mint(address(this), 191_922_690e18);
        // usdc -> 181,045,903
        usdc.mint(address(this), 181_045_903e6);
        // usdt -> 71,514,523
        usdt.mint(address(this), 71_514_523e6);

        uint256[3] memory amounts = [uint256(191_922_690e18), uint256(181_045_903e6), uint256(71_514_523e6)];
        IERC20(TOKENS[0]).approve(address(stableSwap), type(uint256).max);
        IERC20(TOKENS[1]).approve(address(stableSwap), type(uint256).max);
        IERC20(TOKENS[2]).approve(address(stableSwap), type(uint256).max);
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
        uint256 usdcBalInitial = IERC20(tokens[1]).balanceOf(address(this));
        console2.log("daiBalInitial: ", daiBalInitial);
        console2.log("usdcBalInitial: ", usdcBalInitial);

        assertEq(daiBalInitial, 10_000e18);
        assertEq(usdcBalInitial, 0);

        swap(0, 1, 10e18);

        uint256 daiBalAfter = IERC20(tokens[0]).balanceOf(address(this));
        uint256 usdcBalAfter = IERC20(tokens[1]).balanceOf(address(this));
        console2.log("daiBalAfter: ", daiBalAfter);
        console2.log("usdcBalAfter: ", usdcBalAfter);
    }
}
