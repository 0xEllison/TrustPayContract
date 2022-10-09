// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
*@title BlackList
*@author 0xES
*/
contract BlackList is Ownable {

    mapping (address => bool) public isBlackListed;

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    // function destroyBlackFunds (address _blackListedUser) public onlyOwner {
    //     require(isBlackListed[_blackListedUser]);
    //     uint dirtyFunds = balanceOf(_blackListedUser);
    //     balances[_blackListedUser] = 0;
    //     _totalSupply -= dirtyFunds;
    //     DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    // }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

/**
*@title TrustPay Order Contract
*本合约实现了虚拟货币支付场景中的第三方担保交易功能
*在交易过程中，收款方发起订单，付款方将款项支付给本合约暂存，并获得验证码。
*收款方在输入验证码后，可以从合约中提取订单资金。
*过程中，合约会抽取一定比例代币作为手续费。且资金只有收款方有权利提取，若丢失验证码，需要支付代币重新获取
*@author 0xES
*/
contract TrustPay is BlackList{
    using SafeMath for uint256;
    
    event TradeStatusChange(address indexed creator,address indexed payer,uint256 id,uint256 amount,uint8 status);
    event Params(uint feeBasisPoints, uint maxFee);
    uint basisPointsRate = 0;
    uint maximumFee = 0;

    address erc20 = address(0);
    
    mapping(uint256 => Trade) trades;
    uint256 tradeCounter;

    constructor(address _erc20){
        erc20 = _erc20;
    }
    /*Order结构体 规定了订单的基础结构*/
    struct Trade{
        address creator;//创建者，即收款者
        address payer;//付款者，默认为0x0
        uint256 amount;//金额
        uint verify;//提款验证码
        uint8 status; // 1：Open,2：Executed,3:Done
        
    }
    //生成随机数
    //@param number 随机数长度
    function random(uint number) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }
    function compareStr(string memory _str, string memory str) public pure returns (bool) 
    {
        return keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str)); 
    }

    /**
    *新增订单
    *
    */
    function addTrade (uint256 _amount) public{
        require(!isBlackListed[msg.sender],"address has been blocked!");
        trades[tradeCounter] = Trade({
            creator:msg.sender, 
            amount:_amount,
            verify:0,
            payer:address(0),
            status: 1});
        tradeCounter += 1;
        emit TradeStatusChange(msg.sender,address(0),tradeCounter - 1,_amount, 1);
    }
    //获取订单信息
    //@param _id 订单id
    function getTrade(uint256 _id) public view returns(address,address,uint256,uint8){
        require(!isBlackListed[msg.sender],"address has been blocked!");
        Trade memory trade = trades[_id];
        return (trade.creator,trade.payer,trade.amount,trade.status);
    }
 
    //执行订单（付款到本合约暂存）
    //@param _id 订单ID
    function executeTrade(uint256 _id) public{
        require(!isBlackListed[msg.sender],"address has been blocked!");
        Trade memory trade = trades[_id];
        require(trade.status == 1, "Trade is not Open.");
        IERC20 testToken = IERC20(erc20);
        testToken.transferFrom(msg.sender,address(this),trade.amount);
        trade.status = 2;
        trade.payer = msg.sender;
        trade.verify = random(100000);
        trades[_id] = trade;
        
        emit TradeStatusChange(trade.creator,msg.sender,_id,trade.amount, 2);
    }
    
    //获取验证码（只允许付款者调用）
    //@param _id 订单ID
    function getVerify(uint256 _id) public view returns(uint){
        Trade memory trade = trades[_id];
         require(msg.sender == trade.payer,
         "VerifyCode can be read only by payer.");
         return trade.verify;
    }
    //订单提款（合约付款到订单创建人）
    //@param _id 订单ID
    //@param _verify 验证码
    function withdrawTrade(uint256 _id,uint _verify) public{
        require(!isBlackListed[msg.sender],"address has been blocked!");

        Trade memory trade = trades[_id];
         require(msg.sender == trade.creator,
         "Trade can be cancelled only by creator.");
        require(_verify == trade.verify,
        "Verify Code Incorrect!");
        require(trade.status == 2 ,
        "Trade is not Exec.");

        IERC20 testToken = IERC20(erc20);

        uint fee = (trade.amount.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }

        uint sendAmount = trade.amount.sub(fee);
        testToken.transfer(msg.sender,sendAmount);
        
        trade.status = 3;
        trades[_id] = trade;
        // delete trades[_id];
        // tradeCounter -= 1;
        emit TradeStatusChange(trade.creator,trade.payer,_id,trade.amount,3);
    }

    //设置参数 
    //@param newBasisPoints 手续费比例
    //@param newMaxFee 手续费上限
    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**18);

        emit Params(basisPointsRate, maximumFee);
    }
    
}