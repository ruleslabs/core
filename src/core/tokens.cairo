use array::SpanTrait;
use zeroable::Zeroable;
use rules_tokens::utils::serde::SpanSerde;

// locals
use rules_tokens::constants;
use rules_tokens::utils::zeroable::{ U128Zeroable };
use super::interface::{ Token, TokenId, CardToken, PackToken, CardModel, Scarcity, Metadata };
use rules_tokens::typed_data::voucher::Voucher;

#[abi]
trait RulesTokensABI {
  #[view]
  fn voucher_signer() -> starknet::ContractAddress;

  #[view]
  fn card_model(card_model_id: u128) -> CardModel;

  #[view]
  fn card_model_metadata(card_model_id: u128) -> Metadata;

  #[view]
  fn scarcity(season: felt252, scarcity_id: felt252) -> Scarcity;

  #[view]
  fn uncommon_scarcities_count(season: felt252) -> felt252;

  #[external]
  fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128;

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity);

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>);
}

#[contract]
mod RulesTokens {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use rules_erc1155::erc1155::ERC1155;
  use rules_account::account;

  // locals
  use rules_tokens::access::ownable::Ownable;
  use rules_tokens::typed_data::TypedDataTrait;
  use rules_tokens::utils::zeroable::{ CardModelZeroable, U128Zeroable };
  use super::super::interface::{
    IRulesTokens,
    Scarcity,
    CardModel,
    Metadata,
    Voucher,
    CardToken,
    PackToken,
    TokenId,
    Token,
  };
  use super::super::data::RulesData;
  use super::{ TokenIdTrait };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  struct Storage {
    // (receiver, nonce) -> consumed
    _consumed_vouchers: LegacyMap<(starknet::ContractAddress, felt252), bool>,
    _voucher_signer: starknet::ContractAddress,
    // card_token_id -> minted
    _minted_cards: LegacyMap<u256, bool>,
    // TODO: remove contract based marketplace support
    _marketplace: starknet::ContractAddress,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(
    uri_: Span<felt252>,
    voucher_signer_: starknet::ContractAddress,
    marketplace_: starknet::ContractAddress
  ) {
    ERC1155::initializer(:uri_);
    Ownable::initializer();
    initializer(:voucher_signer_, :marketplace_);
  }

  //
  // impls
  //

  impl RulesTokens of IRulesTokens {
    fn voucher_signer() -> starknet::ContractAddress {
      _voucher_signer::read()
    }

    fn card_exists(card_token_id: u256) -> bool {
      _minted_cards::read(card_token_id)
    }

    fn redeem_voucher(voucher: Voucher, signature: Span<felt252>) {
      // assert voucher has not been already consumed and consume it
      assert(!_is_voucher_consumed(:voucher), 'Voucher already consumed');
      _consume_voucher(:voucher);

      // assert voucher signature is valid
      let voucher_signer_ = _voucher_signer::read();
      assert(_is_voucher_signature_valid(:voucher, :signature, signer: voucher_signer_), 'Invalid voucher signature');

      // mint token id
      _mint(to: voucher.receiver, token_id: TokenIdTrait::new(id: voucher.token_id), amount: voucher.amount);
    }
  }

  //
  // Upgrade
  //

  // TODO: use Upgradeable impl with more custom call after upgrade
  #[external]
  fn upgrade(new_implementation: starknet::ClassHash) {
    Ownable::assert_only_owner();

    // set new impl
    starknet::replace_class_syscall(new_implementation);
  }

  // Getters

  #[view]
  fn uri(tokenId: u256) -> Span<felt252> {
    ERC1155::uri(:tokenId)
  }

  #[view]
  fn owner() -> starknet::ContractAddress {
    Ownable::owner()
  }

  #[view]
  fn voucher_signer() -> starknet::ContractAddress {
    RulesTokens::voucher_signer()
  }

  #[view]
  fn card_exists(card_token_id: u256) -> bool {
    RulesTokens::card_exists(:card_token_id)
  }

  // ERC165

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC1155::supports_interface(:interface_id)
  }

  // Ownable

  #[external]
  fn transfer_ownership(new_owner: starknet::ContractAddress) {
    Ownable::transfer_ownership(:new_owner);
  }

  #[external]
  fn renounce_ownership() {
    Ownable::renounce_ownership();
  }

  // Balance

  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
    ERC1155::balance_of(:account, :id)
  }

  #[view]
  fn balance_of_batch(accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Array<u256> {
    ERC1155::balance_of_batch(:accounts, :ids)
  }

  // Approval

  #[external]
  fn set_approval_for_all(operator: starknet::ContractAddress, approved: bool) {
    ERC1155::set_approval_for_all(:operator, :approved)
  }

  #[view]
  fn is_approved_for_all(account: starknet::ContractAddress, operator: starknet::ContractAddress) -> bool {
    ERC1155::is_approved_for_all(:account, :operator)
  }

  // Transfer

  // dirty untested override until meta-transaction based marketplace
  #[external]
  fn safeTransferFrom(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    let caller = starknet::get_caller_address();

    if (caller == _marketplace::read()) {
      ERC1155::_safe_transfer_from(:from, :to, :id, :amount, :data);
    } else {
      ERC1155::safe_transfer_from(:from, :to, :id, :amount, :data);
    }
  }

  #[external]
  fn safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    ERC1155::safe_transfer_from(:from, :to, :id, :amount, :data);
  }

  #[external]
  fn safe_batch_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  ) {
    ERC1155::safe_batch_transfer_from(:from, :to, :ids, :amounts, :data);
  }

  // Card models

  #[view]
  fn card_model(card_model_id: u128) -> CardModel {
    RulesData::card_model(:card_model_id)
  }

  #[view]
  fn card_model_metadata(card_model_id: u128) -> Metadata {
    RulesData::card_model_metadata(:card_model_id)
  }

  #[external]
  fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128 {
    RulesData::add_card_model(:new_card_model, :metadata)
  }

  // Scarcity

  #[view]
  fn scarcity(season: felt252, scarcity_id: felt252) -> Scarcity {
    RulesData::scarcity(:season, :scarcity_id)
  }

  #[view]
  fn uncommon_scarcities_count(season: felt252) -> felt252 {
    RulesData::uncommon_scarcities_count(:season)
  }

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity) {
    RulesData::add_scarcity(:season, :scarcity)
  }

  // Voucher

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>) {
    RulesTokens::redeem_voucher(:voucher, :signature);
  }

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(voucher_signer_: starknet::ContractAddress, marketplace_: starknet::ContractAddress) {
    _voucher_signer::write(voucher_signer_);
    _marketplace::write(marketplace_);
  }

  // Mint

  #[internal]
  fn _mint(to: starknet::ContractAddress, token_id: TokenId, amount: u256) {
    match (token_id.parse()) {
      Token::card(card_token) => {
        _mint_card(:to, :card_token, :amount);
      },
      Token::pack(pack_token) => {
        _mint_pack(:to, :pack_token, :amount);
      },
    }
  }

  #[internal]
  fn _mint_card(to: starknet::ContractAddress, card_token: CardToken, amount: u256) {
    // assert amount is valid
    assert(amount == 1, 'Card amount cannot exceed 1');

    // assert card model exists
    let card_model_ = card_model(card_model_id: card_token.card_model_id);
    assert(card_model_.is_non_zero(), 'Card model does not exists');

    // assert serial number is in a valid range: [1, scarcity max supply]
    let scarcity_ = scarcity(season: card_model_.season, scarcity_id: card_model_.scarcity_id);
    assert(
      card_token.serial_number.is_non_zero() & card_token.serial_number <= scarcity_.max_supply,
      'Serial number is out of range'
    );

    // assert card does not already exists
    assert(!card_exists(card_token_id: card_token.id), 'Card already minted');

    // save card as minted
    _minted_cards::write(card_token.id, true);

    // mint token
    ERC1155::_mint(:to, id: card_token.id, :amount, data: ArrayTrait::<felt252>::new().span());
  }

  #[internal]
  fn _mint_pack(to: starknet::ContractAddress, pack_token: PackToken, amount: u256) {
    panic_with_felt252('Packs tokens not supported yet');
  }

  // Voucher

  #[internal]
  fn _is_voucher_signature_valid(
    voucher: Voucher,
    signature: Span<felt252>,
    signer: starknet::ContractAddress
  ) -> bool {
    // compute voucher message hash
    let hash = voucher.compute_hash_from(from: signer);

    // check signature
    let signer_account = AccountABIDispatcher { contract_address: signer };
    signer_account.is_valid_signature(message: hash, :signature) == account::interface::ERC1271_VALIDATED
  }

  #[internal]
  fn _is_voucher_consumed(voucher: Voucher) -> bool {
    _consumed_vouchers::read((voucher.receiver, voucher.nonce))
  }

  #[internal]
  fn _consume_voucher(voucher: Voucher) {
    _consumed_vouchers::write((voucher.receiver, voucher.nonce), true);
  }
}

trait TokenIdTrait {
  fn new(id: u256) -> TokenId;
  fn parse(self: TokenId) -> Token;
}

impl TokenIdImpl of TokenIdTrait {
  fn new(id: u256) -> TokenId {
    TokenId { id }
  }

  fn parse(self: TokenId) -> Token {
    if (self.id.high.is_non_zero()) {
      Token::card(CardToken {
        serial_number: self.id.high,
        card_model_id: self.id.low,
        id: self.id,
      })
    } else {
      Token::pack(PackToken {
        pack_id: self.id.high,
        id: self.id,
      })
    }
  }
}
