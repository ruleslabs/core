use array::SpanTrait;
use zeroable::Zeroable;
use rules_erc1155::utils::serde::SpanSerde;

// locals
use rules_tokens::constants;
use rules_tokens::utils::zeroable::{ U128Zeroable };
use super::interface::{ Token, TokenId, CardToken, PackToken, CardModel, Scarcity, Metadata, Voucher, Order };

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
  fn upgrade(new_implementation: starknet::ClassHash);

  #[external]
  fn add_card_model(new_card_model: CardModel, metadata: Metadata) -> u128;

  #[external]
  fn add_scarcity(season: felt252, scarcity: Scarcity);

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>);

  #[external]
  fn fulfill_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>);

  #[external]
  fn cancel_order(order: Order, signature: Span<felt252>);

  #[external]
  fn redeem_voucher_and_fulfill_order(
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>
  );
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
  use rules_tokens::typed_data::order::Item;
  use rules_tokens::utils::zeroable::{ CardModelZeroable, U128Zeroable };
  use super::super::interface::{
    IRulesTokens,
    Scarcity,
    CardModel,
    Metadata,
    Voucher,
    Order,
    CardToken,
    PackToken,
    TokenId,
    Token,
  };
  use super::super::data::RulesData;
  use super::super::messages::RulesMessages;
  use super::{ TokenIdTrait };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };
  use rules_tokens::token::erc20::{ IERC20Dispatcher, IERC20DispatcherTrait };
  use rules_erc1155::erc1155::{ ERC1155ABIDispatcher, ERC1155ABIDispatcherTrait };

  //
  // Storage
  //

  struct Storage {
    // card_token_id -> minted
    _minted_cards: LegacyMap<u256, bool>,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(
    uri_: Span<felt252>,
    owner_: starknet::ContractAddress,
    voucher_signer_: starknet::ContractAddress
  ) {
    ERC1155::initializer(:uri_,);
    RulesMessages::initializer(:voucher_signer_);
    initializer(:owner_);
  }

  //
  // impls
  //

  impl RulesTokens of IRulesTokens {
    fn card_exists(card_token_id: u256) -> bool {
      _minted_cards::read(card_token_id)
    }

    fn redeem_voucher(voucher: Voucher, signature: Span<felt252>) {
      RulesMessages::consume_valid_voucher(:voucher, :signature);

      // mint token id
      _mint(to: voucher.receiver, token_id: TokenIdTrait::new(id: voucher.token_id), amount: voucher.amount);
    }

    fn fulfill_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) {
      RulesMessages::consume_valid_order_from(:from, :order, :signature);

      // transfer offer to caller
      let caller = starknet::get_caller_address();

      _transfer_item_from(:from, to: caller, item: order.offer_item);

      // transfer consideration to offerer
      _transfer_item_from(from: caller, to: from, item: order.consideration_item);
    }

    fn cancel_order(order: Order, signature: Span<felt252>) {
      let caller = starknet::get_caller_address();

      RulesMessages::consume_valid_order_from(from: caller, :order, :signature);
    }

    fn redeem_voucher_and_fulfill_order(
      voucher: Voucher,
      voucher_signature: Span<felt252>,
      order: Order,
      order_signature: Span<felt252>
    ) {
      let offerer = voucher.receiver;

      // consume both messages
      RulesMessages::consume_valid_voucher(:voucher, signature: voucher_signature);
      RulesMessages::consume_valid_order_from(from: offerer, :order, signature: order_signature);

      // mint offer to caller
      let caller = starknet::get_caller_address();

      _transfer_item_from(from: starknet::contract_address_const::<0>(), to: caller, item: order.offer_item);

      // transfer consideration to offerer
      _transfer_item_from(from: caller, to: offerer, item: order.consideration_item);
    }
  }

  //
  // Upgrade
  //

  // TODO: use Upgradeable impl with more custom call after upgrade
  #[external]
  fn upgrade(new_implementation: starknet::ClassHash) {
    // Modifiers
    Ownable::assert_only_owner();

    // Body

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
    RulesMessages::voucher_signer()
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
  fn balanceOf(account: starknet::ContractAddress, id: u256) -> u256 {
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
    // Modifiers
    Ownable::assert_only_owner();

    // Body
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
    // Modifiers
    Ownable::assert_only_owner();

    // Body
    RulesData::add_scarcity(:season, :scarcity)
  }

  // Voucher

  #[external]
  fn redeem_voucher(voucher: Voucher, signature: Span<felt252>) {
    RulesTokens::redeem_voucher(:voucher, :signature);
  }

  // Order

  #[external]
  fn fulfill_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) {
    RulesTokens::fulfill_order_from(:from, :order, :signature);
  }

  #[external]
  fn cancel_order(order: Order, signature: Span<felt252>) {
    RulesTokens::cancel_order(:order, :signature);
  }

  #[external]
  fn redeem_voucher_and_fulfill_order(
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>
  ) {
    RulesTokens::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
  }

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(owner_: starknet::ContractAddress) {
    Ownable::_transfer_ownership(new_owner: owner_);
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

  // Order

  #[internal]
  fn _transfer_item_from(from: starknet::ContractAddress, to: starknet::ContractAddress, item: Item) {
    // TODO: add case fallback support

    match item {
      Item::ERC20(erc_20_item) => {
        let ERC20 = IERC20Dispatcher { contract_address: erc_20_item.token };

        ERC20.transferFrom(sender: from, recipient: to, amount: erc_20_item.amount);
      },

      Item::ERC1155(erc_1155_item) => {
        let self = starknet::get_contract_address();

        if (self == erc_1155_item.token) {
          // item is a Rules token

          // Mint if from is zero, or transfer
          if (from.is_zero()) {
            _mint(:to, token_id: TokenIdTrait::new(id: erc_1155_item.identifier), amount: erc_1155_item.amount);
          } else {
            safe_transfer_from(
              :from,
              :to,
              id: erc_1155_item.identifier,
              amount: erc_1155_item.amount,
              data: ArrayTrait::<felt252>::new().span()
            );
          }
        } else {
          // item is a random ERC1155 token

          let ERC1155 = ERC1155ABIDispatcher { contract_address: erc_1155_item.token };

          ERC1155.safe_transfer_from(
            :from,
            :to,
            id: erc_1155_item.identifier,
            amount: erc_1155_item.amount,
            data: ArrayTrait::<felt252>::new().span()
          );
        }
      },
    }
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
