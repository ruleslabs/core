import pytest
import asyncio
import dill
import sys
import time
from types import SimpleNamespace

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import get_selector_from_name

from utils.Signer import Signer
from utils.misc import (
  declare, deploy_proxy, serialize_contract, unserialize_contract, serialize_class, unserialize_class,
  set_block_timestamp, uint, str_to_felt, to_starknet_args,
)
from utils.TransactionSender import TransactionSender


# pytest-xdest only shows stderr
sys.stdout = sys.stderr

initialize_selector = get_selector_from_name('initialize')

BASE_URI = 0x42

@pytest.fixture(scope='module')
def event_loop():
  return asyncio.new_event_loop()


async def build_copyable_deployment():
  starknet = await Starknet.empty()

  # initialize realistic timestamp
  set_block_timestamp(starknet.state, round(time.time()))

  # Signers
  signers = dict(
    owner=Signer(8245892928310),
    minter=Signer(1004912350233),
    rando1=Signer(1111111111111),
    rando2=Signer(2222222222222),
    rando3=Signer(3333333333333)
  )

  # Classes
  account_class = await declare(starknet, 'periphery/account/Account.cairo')

  rules_class = await declare(starknet, 'src/ruleslabs/Rules.cairo')

  upgrade_class = await declare(starknet, 'src/test/upgrade.cairo')

  # Accounts
  accounts = SimpleNamespace(
    **{
      name: (await deploy_proxy(
        starknet,
        account_class.abi,
        [account_class.class_hash, initialize_selector, 2, signer.public_key, 0]
      ))
      for name, signer in signers.items()
    }
  )

  # Proxies
  rules = await deploy_proxy(
    starknet,
    rules_class.abi,
    [
      rules_class.class_hash,
      initialize_selector,
      3,
      1,
      BASE_URI,
      accounts.owner.contract_address,
    ],
  )

  # Access control
  owner_sender = TransactionSender(accounts.owner)

  await owner_sender.send_transaction([
    (rules.contract_address, 'addMinter', [accounts.minter.contract_address]),
  ], signers['owner'])

  return SimpleNamespace(
    starknet=starknet,
    signers=signers,
    serialized_accounts=dict(
      owner=serialize_contract(accounts.owner, account_class.abi),
      minter=serialize_contract(accounts.minter, account_class.abi),
      rando1=serialize_contract(accounts.rando1, account_class.abi),
      rando2=serialize_contract(accounts.rando2, account_class.abi),
      rando3=serialize_contract(accounts.rando3, account_class.abi),
    ),
    serialized_contracts=dict(
      rules=serialize_contract(rules, rules_class.abi),
    ),
    serialized_classes=dict(
      upgrade=serialize_class(upgrade_class),
    ),
  )


@pytest.fixture(scope='module')
async def copyable_deployment(request):
  CACHE_KEY='deployment'
  val = request.config.cache.get(CACHE_KEY, None)

  if val is None:
    val = await build_copyable_deployment()
    res = dill.dumps(val).decode('cp437')
    request.config.cache.set(CACHE_KEY, res)
  else:
    val = dill.loads(val.encode('cp437'))

  return val


@pytest.fixture(scope='module')
async def ctx_factory(copyable_deployment):
  serialized_contracts = copyable_deployment.serialized_contracts
  serialized_accounts = copyable_deployment.serialized_accounts
  serialized_classes = copyable_deployment.serialized_classes
  signers = copyable_deployment.signers

  def make():
    starknet_state = copyable_deployment.starknet.state.copy()
    contracts = {
      name: unserialize_contract(starknet_state, serialized_contract)
      for name, serialized_contract in serialized_contracts.items()
    }
    accounts = {
      name: unserialize_contract(starknet_state, serialized_account)
      for name, serialized_account in serialized_accounts.items()
    }
    classes = {
      name: unserialize_class(serialized_class)
      for name, serialized_class in serialized_classes.items()
    }

    async def execute(account_name, contract_address, selector_name, calldata):
      sender = TransactionSender(accounts[account_name])

      return await sender.send_transaction([
        (contract_address, selector_name, calldata)
      ], signers[account_name])

    return SimpleNamespace(
      starknet=Starknet(starknet_state),
      execute=execute,
      signers=signers,
      **accounts,
      **contracts,
      **classes,
    )

  return make
