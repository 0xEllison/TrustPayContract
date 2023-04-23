pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Product is ERC1155 {
    mapping(uint256 => uint256) private _balances;

    constructor() ERC1155("https://example.com/token/{id}.json") {}

    function mint(uint256 id, uint256 amount) public {
        // 添加新商品
        if (_balances[id] == 0) {
            _mint(msg.sender, id, amount, "");
        } else {
            // 增加现有商品的存量
            _balances[id] += amount;
            _mint(msg.sender, id, amount, "");
        }
    }

    function burn(uint256 id, uint256 amount) public {
        _balances[id] -= amount;
        _burn(msg.sender, id, amount);
    }

    function balanceOf(uint256 id) public view returns (uint256) {
        return _balances[id];
    }
}