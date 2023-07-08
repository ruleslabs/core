use array::{ SpanTrait, SpanSerde };
use zeroable::Zeroable;

// locals
use rules_tokens::constants;
use super::interface::{ Token, TokenId, CardToken, PackToken, CardModel, Scarcity, Metadata, Voucher };

#[starknet::interface]
trait RulesTokensABI<TContractState> {
  fn voucher_signer(self: @TContractState) -> starknet::ContractAddress;

  fn contract_uri(self: @TContractState) -> Span<felt252>;

  fn marketplace(self: @TContractState) -> starknet::ContractAddress;

  fn card_model(self: @TContractState, card_model_id: u128) -> CardModel;

  fn card_model_metadata(self: @TContractState, card_model_id: u128) -> Metadata;

  fn scarcity(self: @TContractState, season: felt252, scarcity_id: felt252) -> Scarcity;

  fn uncommon_scarcities_count(self: @TContractState, season: felt252) -> felt252;

  fn royalty_info(self: @TContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);

  fn set_contract_uri(ref self: TContractState, contract_uri_: Span<felt252>);

  fn set_royalties_receiver(ref self: TContractState, new_receiver: starknet::ContractAddress);

  fn set_royalties_percentage(ref self: TContractState, new_percentage: u16);

  fn upgrade(ref self: TContractState, new_implementation: starknet::ClassHash);

  fn set_marketplace(ref self: TContractState, marketplace_: starknet::ContractAddress);

  fn add_card_model(ref self: TContractState, new_card_model: CardModel, metadata: Metadata) -> u128;

  fn add_scarcity(ref self: TContractState, season: felt252, scarcity: Scarcity);

  fn redeem_voucher(ref self: TContractState, voucher: Voucher, signature: Span<felt252>);

  fn owner(self: @TContractState) -> starknet::ContractAddress;

  fn transfer_ownership(ref self: TContractState, new_owner: starknet::ContractAddress);

  fn renounce_ownership(ref self: TContractState);
}

#[starknet::contract]
mod RulesTokens {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use rules_erc1155::erc1155;
  use rules_erc1155::erc1155::ERC1155;
  use rules_account::account;
  use messages::typed_data::TypedDataTrait;
  use integer::U128Zeroable;
  use rules_utils::utils::storage::Felt252SpanStorageAccess;

  // locals
  use rules_tokens::core;
  use rules_tokens::core::interface::{
    IRulesMessages,
    IRulesData,
    IRulesTokens,
    IRulesTokensCamelCase,
    Scarcity,
    CardModel,
    Metadata,
    Voucher,
    CardToken,
    PackToken,
    TokenId,
    Token,
  };
  use rules_tokens::core::data::RulesData;
  use rules_tokens::core::messages::RulesMessages;

  use rules_tokens::access::ownable;
  use rules_tokens::access::ownable::Ownable;

  use rules_tokens::introspection::erc165;
  use rules_tokens::introspection::erc165::ERC165;

  use rules_tokens::royalties::erc2981;
  use rules_tokens::royalties::erc2981::ERC2981;

  use rules_tokens::utils::zeroable::{ CardModelZeroable };
  use super::TokenIdTrait;

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage {
    // card_token_id -> minted
    _minted_cards: LegacyMap<u256, bool>,

    // Marketplace address
    _marketplace: starknet::ContractAddress,

    // Contract uri
    _contract_uri: Span<felt252>,
  }

  //
  // Modifiers
  //

  #[generate_trait]
  impl ModifierImpl of ModifierTrait {
    // TODO: access control
    fn _only_marketplace(self: @ContractState) {
      let caller = starknet::get_caller_address();
      let marketplace_ = self.marketplace();

      assert(caller.is_non_zero(), 'Caller is the zero address');
      assert(marketplace_ == caller, 'Caller is not the marketplace');
    }

    fn _only_owner(self: @ContractState) {
      let ownable_self = Ownable::unsafe_new_contract_state();

      Ownable::ModifierImpl::assert_only_owner(self: @ownable_self);
    }
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(
    ref self: ContractState,
    uri_: Span<felt252>,
    owner_: starknet::ContractAddress,
    voucher_signer_: starknet::ContractAddress,
    contract_uri_: Span<felt252>,
    marketplace_: starknet::ContractAddress,
    royalties_receiver_: starknet::ContractAddress,
    royalties_percentage_: u16
  ) {
    self.initializer(
      :uri_,
      :owner_,
      :voucher_signer_,
      :contract_uri_,
      :marketplace_,
      :royalties_receiver_,
      :royalties_percentage_
    );
  }

  //
  // Upgrade
  //

  // TODO: use Upgradeable impl with more custom call after upgrade

  #[generate_trait]
  #[external(v0)]
  impl UpgradeImpl of UpgradeTrait {
    fn upgrade(ref self: ContractState, new_implementation: starknet::ClassHash) {
      // Modifiers
      self._only_owner();

      // Body

      // set new impl
      starknet::replace_class_syscall(new_implementation);
    }
  }

  //
  // Rules Tokens impl
  //

  #[external(v0)]
  impl IRulesTokensImpl of core::interface::IRulesTokens<ContractState> {
    fn contract_uri(self: @ContractState) -> Span<felt252> {
      self._contract_uri.read()
    }

    fn marketplace(self: @ContractState) -> starknet::ContractAddress {
      self._marketplace.read()
    }

    fn card_exists(self: @ContractState, card_token_id: u256) -> bool {
      self._minted_cards.read(card_token_id)
    }

    fn set_contract_uri(ref self: ContractState, contract_uri_: Span<felt252>) {
      // Modifiers
      self._only_owner();

      // Body
      self._contract_uri.write(contract_uri_);
    }

    fn set_marketplace(ref self: ContractState, marketplace_: starknet::ContractAddress) {
      // Modifiers
      self._only_owner();

      // Body
      self._marketplace.write(marketplace_);
    }

    fn redeem_voucher(ref self: ContractState, voucher: Voucher, signature: Span<felt252>) {
      let mut rules_messages_self = RulesMessages::unsafe_new_contract_state();

      RulesMessages::IRulesMessages::consume_valid_voucher(ref self: rules_messages_self, :voucher, :signature);

      // mint token id
      self._mint(to: voucher.receiver, token_id: TokenIdTrait::new(id: voucher.token_id), amount: voucher.amount);
    }

    fn redeem_voucher_to(
      ref self: ContractState,
      to: starknet::ContractAddress,
      voucher: Voucher,
      signature: Span<felt252>
    ) {
      // Modifiers
      self._only_marketplace();

      // Body
      let mut rules_messages_self = RulesMessages::unsafe_new_contract_state();

      RulesMessages::IRulesMessages::consume_valid_voucher(ref self: rules_messages_self, :voucher, :signature);

      // mint token id
      self._mint(:to, token_id: TokenIdTrait::new(id: voucher.token_id), amount: voucher.amount);
    }

    // ERC2981

    fn set_royalties_receiver(ref self: ContractState, new_receiver: starknet::ContractAddress) {
      // Modifiers
      self._only_owner();

      // Body
      let mut erc2981_self = ERC2981::unsafe_new_contract_state();

      ERC2981::HelperImpl::_set_royalty_receiver(ref self: erc2981_self, :new_receiver);
    }

    fn set_royalties_percentage(ref self: ContractState, new_percentage: u16) {
      // Modifiers
      self._only_owner();

      // Body
      let mut erc2981_self = ERC2981::unsafe_new_contract_state();

      ERC2981::HelperImpl::_set_royalty_percentage(ref self: erc2981_self, :new_percentage);
    }
  }

  //
  // Rules Messages impl
  //

  #[external(v0)]
  impl IRulesMessagesImpl of core::interface::IRulesMessages<ContractState> {
    fn voucher_signer(self: @ContractState) -> starknet::ContractAddress {
      let rules_messages_self = RulesMessages::unsafe_new_contract_state();

      RulesMessages::IRulesMessagesImpl::voucher_signer(self: @rules_messages_self)
    }

    fn consume_valid_voucher(ref self: ContractState, voucher: Voucher, signature: Span<felt252>) {
      let mut rules_messages_self = RulesMessages::unsafe_new_contract_state();

      RulesMessages::IRulesMessagesImpl::consume_valid_voucher(ref self: rules_messages_self, :voucher, :signature);
    }
  }

  //
  // IRulesData impl
  //

  #[external(v0)]
  impl IRulesDataImpl of core::interface::IRulesData<ContractState> {
    fn card_model(self: @ContractState, card_model_id: u128) -> CardModel {
      let rules_data_self = RulesData::unsafe_new_contract_state();

      RulesData::IRulesDataImpl::card_model(self: @rules_data_self, :card_model_id)
    }

    fn card_model_metadata(self: @ContractState, card_model_id: u128) -> Metadata {
      let rules_data_self = RulesData::unsafe_new_contract_state();

      RulesData::IRulesDataImpl::card_model_metadata(self: @rules_data_self, :card_model_id)
    }

    fn scarcity(self: @ContractState, season: felt252, scarcity_id: felt252) -> Scarcity {
      let rules_data_self = RulesData::unsafe_new_contract_state();

      RulesData::IRulesDataImpl::scarcity(self: @rules_data_self, :season, :scarcity_id)
    }

    fn uncommon_scarcities_count(self: @ContractState, season: felt252) -> felt252 {
      let rules_data_self = RulesData::unsafe_new_contract_state();

      RulesData::IRulesDataImpl::uncommon_scarcities_count(self: @rules_data_self, :season)
    }

    fn add_card_model(ref self: ContractState, new_card_model: CardModel, metadata: Metadata) -> u128 {
      // Modifiers
      self._only_owner();

      // Body
      let mut rules_data_self = RulesData::unsafe_new_contract_state();

      RulesData::IRulesDataImpl::add_card_model(ref self: rules_data_self, :new_card_model, :metadata)
    }

    fn add_scarcity(ref self: ContractState, season: felt252, scarcity: Scarcity) {
      // Modifiers
      self._only_owner();

      // Body
      let mut rules_data_self = RulesData::unsafe_new_contract_state();

      RulesData::IRulesDataImpl::add_scarcity(ref self: rules_data_self, :season, :scarcity)
    }
  }

  //
  // Rules Tokens Camel case impl
  //

  #[external(v0)]
  impl RulesTokensCamelCase of core::interface::IRulesTokensCamelCase<ContractState> {
    fn contractURI(self: @ContractState) -> Span<felt252> {
      self.contract_uri()
    }
  }

  //
  // ERC1155 impl
  //

  #[external(v0)]
  impl IERC1155Impl of erc1155::interface::IERC1155<ContractState> {
    fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      ERC1155::IERC1155Impl::uri(self: @erc1155_self, :token_id)
    }

    fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      ERC1155::IERC1155Impl::balance_of(self: @erc1155_self, :account, :id)
    }

    fn balance_of_batch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Array<u256> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      ERC1155::IERC1155Impl::balance_of_batch(self: @erc1155_self, :accounts, :ids)
    }

    fn is_approved_for_all(self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      ERC1155::IERC1155Impl::is_approved_for_all(self: @erc1155_self, :account, :operator)
    }

    fn set_approval_for_all(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      ERC1155::IERC1155Impl::set_approval_for_all(ref self: erc1155_self, :operator, :approved);
    }

    fn safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      let caller = starknet::get_caller_address();
      let marketplace = self.marketplace();

      if (caller == marketplace) {
        ERC1155::HelperImpl::_safe_transfer_from(ref self: erc1155_self, :from, :to, :id, :amount, :data);
      } else {
        ERC1155::IERC1155Impl::safe_transfer_from(ref self: erc1155_self, :from, :to, :id, :amount, :data);
      }
    }

    fn safe_batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      ERC1155::IERC1155Impl::safe_batch_transfer_from(ref self: erc1155_self, :from, :to, :ids, :amounts, :data);
    }
  }

  //
  // IERC165 impl
  //

  #[external(v0)]
  impl IERC165Impl of erc165::IERC165<ContractState> {
    fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();
      let erc2981_self = ERC2981::unsafe_new_contract_state();

      ERC1155::IERC165Impl::supports_interface(self: @erc1155_self, :interface_id) |
      ERC2981::IERC165Impl::supports_interface(self: @erc2981_self, :interface_id)
    }
  }

  //
  // IERC2981 impl
  //

  #[external(v0)]
  impl IERC2981Impl of erc2981::IERC2981<ContractState> {
    fn royalty_info(self: @ContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
      let erc2981_self = ERC2981::unsafe_new_contract_state();

      ERC2981::IERC2981Impl::royalty_info(self: @erc2981_self, :token_id, :sale_price)
    }
  }

  //
  // Ownable impl
  //

  #[external(v0)]
  impl IOwnableImpl of ownable::IOwnable<ContractState> {
    fn owner(self: @ContractState) -> starknet::ContractAddress {
      let ownable_self = Ownable::unsafe_new_contract_state();

      Ownable::IOwnableImpl::owner(self: @ownable_self)
    }

    fn transfer_ownership(ref self: ContractState, new_owner: starknet::ContractAddress) {
      let mut ownable_self = Ownable::unsafe_new_contract_state();

      Ownable::IOwnableImpl::transfer_ownership(ref self: ownable_self, :new_owner);
    }

    fn renounce_ownership(ref self: ContractState) {
      let mut ownable_self = Ownable::unsafe_new_contract_state();

      Ownable::IOwnableImpl::renounce_ownership(ref self: ownable_self);
    }
  }

  //
  // Helpers
  //

  #[generate_trait]
  impl HelperImpl of HelperTrait {

    // Init

    fn initializer(
      ref self: ContractState,
      uri_: Span<felt252>,
      owner_: starknet::ContractAddress,
      voucher_signer_: starknet::ContractAddress,
      contract_uri_: Span<felt252>,
      marketplace_: starknet::ContractAddress,
      royalties_receiver_: starknet::ContractAddress,
      royalties_percentage_: u16
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();
      let mut rules_messages_self = RulesMessages::unsafe_new_contract_state();
      let mut ownable_self = Ownable::unsafe_new_contract_state();
      let mut erc2981_self = ERC2981::unsafe_new_contract_state();

      ERC1155::HelperImpl::initializer(ref self: erc1155_self, :uri_,);
      RulesMessages::HelperImpl::initializer(ref self: rules_messages_self, :voucher_signer_);

      Ownable::HelperImpl::_transfer_ownership(ref self: ownable_self, new_owner: owner_);

      self._contract_uri.write(contract_uri_);

      self._marketplace.write(marketplace_);

      ERC2981::HelperImpl::_set_royalty_receiver(ref self: erc2981_self, new_receiver: royalties_receiver_);
      ERC2981::HelperImpl::_set_royalty_percentage(ref self: erc2981_self, new_percentage: royalties_percentage_);
    }

    // Mint

    fn _mint(ref self: ContractState, to: starknet::ContractAddress, token_id: TokenId, amount: u256) {
      match (token_id.parse()) {
        Token::card(card_token) => {
          self._mint_card(:to, :card_token, :amount);
        },
        Token::pack(pack_token) => {
          self._mint_pack(:to, :pack_token, :amount);
        },
      }
    }

    fn _mint_card(ref self: ContractState, to: starknet::ContractAddress, card_token: CardToken, amount: u256) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      // assert amount is valid
      assert(amount == 1, 'Card amount cannot exceed 1');

      // assert card model exists
      let card_model_ = self.card_model(card_model_id: card_token.card_model_id);
      assert(card_model_.is_non_zero(), 'Card model does not exists');

      // assert serial number is in a valid range: [1, scarcity max supply]
      let scarcity_ = self.scarcity(season: card_model_.season, scarcity_id: card_model_.scarcity_id);
      assert(
        card_token.serial_number.is_non_zero() & (card_token.serial_number <= scarcity_.max_supply),
        'Serial number is out of range'
      );

      // assert card does not already exists
      assert(!self.card_exists(card_token_id: card_token.id), 'Card already minted');

      // save card as minted
      self._minted_cards.write(card_token.id, true);

      // mint token
      ERC1155::HelperImpl::_mint(
        ref self: erc1155_self,
        :to,
        id: card_token.id,
        :amount,
        data: ArrayTrait::<felt252>::new().span()
      );
    }

    fn _mint_pack(ref self: ContractState, to: starknet::ContractAddress, pack_token: PackToken, amount: u256) {
      panic_with_felt252('Packs tokens not supported yet');
    }
  }
}

#[generate_trait]
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
