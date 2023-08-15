// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import "../src/Solidity/ERC7399Lender.sol";
import { FlashBorrower } from "./stub/FlashBorrower.sol";
import { ERC20Mock } from "./stub/ERC20Mock.sol";
import { IERC20 } from "../src/Solidity/interfaces/IERC20.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract ERC7399LenderTest is PRBTest, StdCheats {
    ERC7399Lender internal lender;
    FlashBorrower internal borrower;
    address internal asset;
    address internal otherAsset;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.

        asset = address(new ERC20Mock("Asset", "AST"));
        ERC20Mock(asset).approve(0x2e234DAe75C793f67A35089C9d99245E1C58470b, type(uint256).max);
        lender = new ERC7399Lender(ERC20Mock(asset), 10);

        string memory ConstantsWrapper = vm.readFile("test/HuffWrappers/ConstantsWrapper.huff");
        lender = ERC7399Lender(
            payable(
                HuffDeployer.config().with_code(ConstantsWrapper).with_args(abi.encode(address(this))).deploy(
                    "ERC7399Lender"
                )
            )
        );
        console2.log(address(this));

        borrower = new FlashBorrower(lender);

        ERC20Mock(asset).approve(address(lender), type(uint256).max);
        lender.deposit(1000e18);
    }

    /// @dev Simple flash loan test.
    function test_flash() external {
        console2.log("test_flash");
        uint256 lenderBalance = IERC20(asset).balanceOf(address(lender));
        uint256 loan = 1e18;
        uint256 fee = lender.flashFee(asset, loan);
        ERC20Mock(asset).mint(address(this), fee);
        IERC20(asset).transfer(address(borrower), fee);
        borrower.flashBorrow(asset, loan);

        assertEq(borrower.flashInitiator(), address(borrower));
        assertEq(address(borrower.flashAsset()), address(asset));
        assertEq(borrower.flashAmount(), loan);
        assertEq(borrower.flashBalance(), loan + fee); // The amount we transferred to pay for fees, plus the amount we
            // borrowed
        assertEq(borrower.flashFee(), fee);
        assertEq(IERC20(asset).balanceOf(address(lender)), lenderBalance + fee);
    }

    // function test_flashAndReenter() external {
    //     console2.log("test_flashAndReenter");
    //     uint256 lenderBalance = IERC20(asset).balanceOf(address(lender));
    //     uint256 firstLoan = 1e18;
    //     uint256 secondLoan = 2e18;
    //     uint256 fees = lender.flashFee(asset, firstLoan) + lender.flashFee(asset, secondLoan);
    //     ERC20Mock(asset).mint(address(this), fees);
    //     IERC20(asset).transfer(address(borrower), fees);
    //     borrower.flashBorrowAndReenter(asset, firstLoan);

    //     assertEq(borrower.flashInitiator(), address(borrower));
    //     assertEq(address(borrower.flashAsset()), address(asset));
    //     assertEq(borrower.flashAmount(), firstLoan + secondLoan);
    //     assertEq(borrower.flashBalance(), firstLoan + secondLoan + fees); // The amount we transferred to pay for
    //         // plus the amount we borrowed
    //     assertEq(borrower.flashFee(), fees);
    //     assertEq(IERC20(asset).balanceOf(address(lender)), lenderBalance + fees);
    // }
}
