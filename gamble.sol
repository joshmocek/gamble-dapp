pragma solidity ^0.4.19;
import "./ownable.sol";
import "./safemath.sol";

contract Gamble {
    using SafeMath for uint256;
    event NewZombie(uint zombieId, string name, uint dna);

    uint houseCut = 1;
    uint amountOfNumbers = 3;
    uint totalPlayers = 0;
    uint[] totalBetColor;
    uint totalAmountBet;
    uint nonce;
    
    mapping (address => uint) ownerBetCount;
    mapping (address => uint256) balanceOf;
    mapping (address => uint) ownerBetAmount;
    mapping (address => uint8) ownerBetColor;
    mapping (uint => address) playerAddress;
    
    function random() internal returns (uint) {
        uint randomNum = uint(keccak256(now, msg.sender, nonce)) % amountOfNumbers;
        nonce++;
        return randomNum;
    }
    
    function _startOver() private {
        totalPlayers = 0;
        totalAmountBet = 0;
        nonce = 0;
        for(uint i = 0; i < amountOfNumbers; i++){
            totalBetColor[i] = 0;
        }
    }
    
    function _createBet(uint _betAmount, uint8 _color) private {
        require(ownerBetCount[msg.sender] == 0);
        require(balanceOf[msg.sender] >= _betAmount);           
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_betAmount);                    
        balanceOf[address(this)] = balanceOf[address(this)].add(_betAmount);
        ownerBetCount[msg.sender] = 1;
        ownerBetColor[msg.sender] = _color;
        ownerBetAmount[msg.sender] = _betAmount;
        totalBetColor[_color] = totalBetColor[_color].add(_betAmount);
        totalAmountBet = totalAmountBet.add(_betAmount);
        totalPlayers = totalPlayers.add(1);
        playerAddress[totalPlayers] = msg.sender;
    }
    
    function _whoWon() private {
        uint winningNumber = random();
        uint leftovers = (totalAmountBet * (1 - houseCut/100)) - totalBetColor[winningNumber];
        for (uint i = 1; i <= totalPlayers; i++){
            address addr = playerAddress[i];
            if(ownerBetColor[addr] == winningNumber){
                _playerWon(addr, ownerBetAmount[addr], totalBetColor[winningNumber], leftovers);
            }
            delete ownerBetCount[addr];
            delete ownerBetColor[addr];
            delete ownerBetAmount[addr];
            delete playerAddress[i];
        }
        _startOver();
    }
    
    function _playerWon(address _addr, uint _amount, uint _winningPot,  uint _leftovers) internal {
        uint payout = (_amount * (1 - houseCut/100)) + ((_amount/_winningPot) * _leftovers);
        _addr.transfer(payout);
        balanceOf[_addr] = balanceOf[_addr].add(payout);                    
        balanceOf[address(this)] = balanceOf[address(this)].sub(payout);
    }
}
