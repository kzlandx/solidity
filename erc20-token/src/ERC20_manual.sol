// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// https://eips.ethereum.org/EIPS/eip-20
contract ERC20 {
    mapping (address => uint256) private s_balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public pure returns (string memory) {
        return "Kimi Token";
    }

    // function symbol() public pure returns (string memory) {}

    function decimals() public pure returns (uint8) {
        return 18; // 1 token = 1e18 small token (like wei)
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether; // 100 tokens
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return s_balances[_owner];
    }

    // function transfer(address _to, uint256 _value) public returns (bool success) {}

    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    
    // function approve(address _spender, uint256 _value) public returns (bool success) {}

    // function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}
}