pragma solidity ^0.8.6;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
  using Roles for Roles.Role;

  event WhitelistAdminAdded(address indexed account);
  event WhitelistAdminRemoved(address indexed account);

  Roles.Role private _whitelistAdmins;

  constructor ()  {
    _addWhitelistAdmin(_msgSender());
  }

  modifier onlyWhitelistAdmin() {
    require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
    _;
  }

  function isWhitelistAdmin(address account) public view returns (bool) {
    return _whitelistAdmins.has(account);
  }

  function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
    _addWhitelistAdmin(account);
  }

  function renounceWhitelistAdmin() public {
    _removeWhitelistAdmin(_msgSender());
  }

  function _addWhitelistAdmin(address account) internal {
    _whitelistAdmins.add(account);
    emit WhitelistAdminAdded(account);
  }

  function _removeWhitelistAdmin(address account) internal {
    _whitelistAdmins.remove(account);
    emit WhitelistAdminRemoved(account);
  }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor ()  {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        require (account != address(this));
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

//Pepemon Factory Interface
interface IPepemonFactory{
    function totalSupply(uint _id) external view returns (uint);
    function maxSupply(uint256 _id) external view returns (uint256);
    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external;
        function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
contract ERC1155Holder{
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
contract PepemonBoosterPack is WhitelistAdminRole, ERC1155, MinterRole, ERC1155Holder {

  IPepemonFactory public PepemonFactory;

  struct Card {
    uint128 cardId;
    uint128 mintableSupply;
  }

  struct BoosterpackSnapshot {
    uint128 maxSupply;
    uint128 amountOfCardsToWin;
    Card[] mintableCards;
  }

  struct Boosterpack {
    uint64 maxSupply;
    uint64 currentSupply;
    uint64 amountOfCardsToWin;
    uint64 totalCardsLeft;
    Card[] mintableCards;
    BoosterpackSnapshot boosterpackSnapshot;  // Boosterpack snapshot that has all the initial values at boosterpack creation
  }

  struct CardWinnings {
    uint256[] cardIds;
  }

    string public constant name = "PepemonBoosterPack";
    string public constant symbol = "PEPEBOOST";
  /**
   * @dev
   * Used as seed for the random number generator
   **/
  uint256 private counter;

  /**
   * @dev
   * Since we cannot get the length of the mapping of boosterpacks, we use a boosterpack index variable
   **/
  uint256 private boosterPackIndex;
 
  mapping(uint256 => Boosterpack) public boosterpacks;

  event PepemonFactoryAddressChange(IPepemonFactory newPepemonFactory, string message);
  event AddedBoosterpack(uint256 boosterpack, uint64 maxSupply, uint128[] cards, uint128[] supply);
  event UpdatedBoosterpack(uint64 boosterpack, uint64 currentSupply, uint64 maxSupply, uint128[] mintableCards);
  event MintedBoosterpack(uint64 boosterpack, address account, uint256[] cardIds);


  constructor(string memory _uri, IPepemonFactory pepefactory) ERC1155(_uri){
    counter = uint256(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp)));
     PepemonFactory = pepefactory;
  }
    function setURI(string memory _uri) public{
        _setURI(_uri);    
    }
        /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function uri(uint id) public view override returns (string memory){
        return string(abi.encodePacked(super.uri(id), toString(id)));
    }
  /**
     * @dev
     * The counter could be set by the Store contract to allow for a random number
     * which cannot be traced back and guess the winnings of the cards
     **/
  function setCounter(uint256 _counter) public onlyWhitelistAdmin {
    counter = _counter;
  }

  /**
   * @dev
   * Allow whitelist admins to change the PepemonFactory contract address
   **/
  function changePepemonFactoryAddress(IPepemonFactory _newPepemonFactoryAddress) public onlyWhitelistAdmin {
    PepemonFactory = _newPepemonFactoryAddress;
    emit PepemonFactoryAddressChange(PepemonFactory, "Changed PepemonFactory address");
  }

  /**
   * @dev
   * Calculates and returns the mintable boosterpack supply
   **/
  function getMintableSupplyBoosterpack(uint256 _boosterpack) public view returns (uint256) {
    require(boosterpacks[_boosterpack].maxSupply!=0, "Boosterpack does not exists");
    return boosterpacks[_boosterpack].maxSupply - (boosterpacks[_boosterpack].currentSupply);
  }

   
  /**
   * @dev
   * Returns the max supply from a bosoterpack, but not necessary the mintable supply
   **/
  function getMaxSupplyBoosterpack(uint256 _boosterpack) public view returns (uint256) {
     require(boosterpacks[_boosterpack].maxSupply!=0, "Boosterpack does not exists");
    return boosterpacks[_boosterpack].maxSupply;
  }

  /**
   * @dev
   * Returns the currentSupply from the boosterpack, may change if calculateMintableBoosterpackSupplyAndCardWinningPercentage is called.
   **/
   function getCurrentSupplyBoosterpack(uint256 _boosterpack) public view returns (uint256) {
    require(boosterpacks[_boosterpack].maxSupply!=0, "Boosterpack does not exists");
    return boosterpacks[_boosterpack].currentSupply;
  }
  
  /**
   * @dev
   * Returns only the mintable cards for the boosterpack WITHOUT their winning percentage
   **/
  function getBoosterpackCards(uint256 _boosterpack) public view returns (Card[] memory) {
     require(boosterpacks[_boosterpack].maxSupply!=0, "Boosterpack does not exists");
     return boosterpacks[_boosterpack].mintableCards;
  }

  /**
 * @dev
 * Create a new boosterpack with corresponding snapshot
 * and calculate it's winnings
 **/
  function createNewBoosterpack(uint64 _maxSupplyBoosterpack, uint128[] memory _cardsInBoosterpack, uint128[] memory supply, uint64 _amountOfCardsToWin) public onlyWhitelistAdmin {
    // Update the boosterpack index + 1
    boosterPackIndex++;
    require(_cardsInBoosterpack.length == supply.length, "LEN MISMATCH");
    uint64 totalCards = _maxSupplyBoosterpack * _amountOfCardsToWin;
    
    uint256 _boosterpack = boosterPackIndex;
    
    Boosterpack storage _boosterpackPlaceholder = boosterpacks[_boosterpack];
    _boosterpackPlaceholder.maxSupply = _maxSupplyBoosterpack;
    _boosterpackPlaceholder.currentSupply = 0;
    _boosterpackPlaceholder.amountOfCardsToWin = _amountOfCardsToWin;

    _boosterpackPlaceholder.boosterpackSnapshot.maxSupply = _maxSupplyBoosterpack;
    boosterpacks[_boosterpack].boosterpackSnapshot.amountOfCardsToWin = _amountOfCardsToWin;
    boosterpacks[_boosterpack].totalCardsLeft = totalCards;
    uint256 t = 0;
    for (uint i = 0; i < supply.length; i++){
        t+=supply[i];
        PepemonFactory.mint(address(this), _cardsInBoosterpack[i], supply[i], "");
        Card memory temp = Card(_cardsInBoosterpack[i], supply[i]);
        _boosterpackPlaceholder.mintableCards.push(temp);
        _boosterpackPlaceholder.boosterpackSnapshot.mintableCards.push(temp);
    }
    require(t == totalCards, "SUPPLY MISMATCH");
    

    emit AddedBoosterpack(_boosterpack, boosterpacks[_boosterpack].maxSupply, _cardsInBoosterpack, supply);
  }


  /**
   * @dev
   * Returns a random number based on an random seed with a range of _range
   **/
  function getRandomNumber(uint256 _range) internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1),  counter)));
    unchecked{
        counter++;
    }
    return randomNumber % _range;
  }


  /**
  * @dev
  * Checks if the cards in the boosterpack are still mintable, if not then return false else True
  * 
  **/
  function isBoosterpackMintable(uint256 _boosterpack) external view returns (bool) {
    require(boosterpacks[_boosterpack].maxSupply!=0, "Boosterpack does not exists");
    require(boosterpacks[_boosterpack].currentSupply < boosterpacks[_boosterpack].maxSupply, "Max boosterpacks minted");
    return true;
  }
  
  function mintBoosterPack(address _to, uint256 _id, uint64 _quantity) public onlyMinter{
      require(boosterpacks[_id].maxSupply!=0, "Boosterpack does not exists");
      require(boosterpacks[_id].currentSupply+ _quantity<= boosterpacks[_id].maxSupply, "MaxSupply reached");
      boosterpacks[_id].currentSupply+=_quantity;
      _mint(_to, _id, _quantity, "");
  }
  
  function unwrapBooster(uint256 _id) public{
      _burn(msg.sender, _id, 1);
      Boosterpack memory bp = boosterpacks[_id];
      for (uint i = 0 ; i < bp.amountOfCardsToWin; i++){
          uint rand = getRandomNumber(bp.totalCardsLeft);
          uint counter2 = 0; 
          uint j;
          for (j = 0; j < bp.mintableCards.length; j++){
              counter2 += bp.mintableCards[j].mintableSupply;
              if (counter2 > rand){
                  break;
              }
          }

          bp.mintableCards[j].mintableSupply--;
          bp.totalCardsLeft--;
          
          boosterpacks[_id].mintableCards[j].mintableSupply = bp.mintableCards[j].mintableSupply;
          boosterpacks[_id].totalCardsLeft = bp.totalCardsLeft;
          PepemonFactory.safeTransferFrom(address(this), msg.sender, bp.mintableCards[j].cardId, 1, "");
      }
  }
      function supportsInterface(bytes4 interfaceId) public view  override(ERC1155) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
