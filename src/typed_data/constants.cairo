const STARKNET_MESSAGE_PREFIX: felt252 = 'StarkNet Message';

// sn_keccak('StarkNetDomain(name:felt252,chainId:felt252,version:felt252)')
const STARKNET_DOMAIN_TYPE_HASH: felt252 = 0x38938178ebdf241a3764698e540ead3e19ed2fb6120e27429961a2378e8b51;

// sn_keccak('Voucher(receiver:felt252,tokenId:u256,amount:u256,salt:felt252)u256(low:felt252,high:felt252)')
const VOUCHER_TYPE_HASH: felt252 = 0x2b7b26b9be07bb06826bb14ffeb28e910317886010a72720cce19e1974bd232;

// sn_keccak('Order(offerItem:Item,considerationItem:Item,endTime:felt252,salt:felt252)Item(token:felt252,identifier:u256,amount:u256,itemType:felt252)u256(low:felt252,high:felt252)')
const ORDER_TYPE_HASH: felt252 = 0xf5cb0008ccf4df0ea7c494dc3453108b2cc44f5baac3214bab30fbfbe1bf40;

// sn_keccak('u256(low:felt252,high:felt252)')
const U256_TYPE_HASH: felt252 = 0x1094260a770342332e6a73e9256b901d484a438925316205b4b6ff25df4a97a;

// sn_keccak('Item(token:felt252,identifier:u256,amount:u256,itemType:felt252)u256(low:felt252,high:felt252)')
const ITEM_TYPE_HASH: felt252 = 0x2f28211a4b264a061fc03d701a04b11e2a0a6d97c4f26fd564b3af79dfb9c1d;

const STARKNET_DOMAIN_NAME: felt252 = 'Rules';
const STARKNET_DOMAIN_VERSION: felt252 = '1.1';
