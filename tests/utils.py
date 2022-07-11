"""Utilities for testing Cairo contracts."""

import inspect
import os
import periphery

from pathlib import Path
from functools import reduce
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.core.os.transaction_hash.transaction_hash import calculate_transaction_hash_common, TransactionHashPrefix
from starkware.starknet.definitions.general_config import StarknetChainId
from itertools import chain

SERIAL_NUMBER_MAX = 2 ** 24 - 1
TRANSACTION_VERSION = 0

_root = Path(__file__).parent.parent


def get_periphery_contract_class(path):
  """Returns the contract definition from libraries"""
  path = os.path.abspath(os.path.dirname(inspect.getfile(periphery))) + "/" + path
  contract_class = compile_starknet_files(
    files=[path],
    debug_info=True
  )
  return contract_class


def get_contract_class(path):
  """Returns the contract definition from the contract path"""
  contract_class = compile_starknet_files(
    files=[str(_root / "src" / path)],
    debug_info=True,
    cairo_path=[str(_root / "src")]
  )
  return contract_class


def from_call_to_call_array(calls):
  call_array = []
  calldata = []
  for i, call in enumerate(calls):
    assert len(call) == 3, "Invalid call parameters"
    entry = (call[0], get_selector_from_name(
      call[1]), len(calldata), len(call[2]))
    call_array.append(entry)
    calldata.extend(call[2])
  return (call_array, calldata)


def get_transaction_hash(account, call_array, calldata, nonce, max_fee):
  execute_calldata = [
    len(call_array),
    *[x for t in call_array for x in t],
    len(calldata),
    *calldata,
    nonce]

  return calculate_transaction_hash_common(
    TransactionHashPrefix.INVOKE,
    TRANSACTION_VERSION,
    account,
    get_selector_from_name('__execute__'),
    execute_calldata,
    max_fee,
    StarknetChainId.TESTNET.value,
    []
  )


class Signer():
  """
  Utility for sending signed transactions to an Account on Starknet.
  Parameters
  ----------
  private_key : int
  Examples
  ---------
  Constructing a Signer object
  >>> signer = Signer(1234)
  Sending a transaction
  >>> await signer.send_transaction(account,
                    account.contract_address,
                    'set_public_key',
                    [other.public_key]
                   )
  """

  def __init__(self, private_key):
    self.private_key = private_key
    self.public_key = private_to_stark_key(private_key)

  def sign(self, message_hash):
    return sign(msg_hash=message_hash, priv_key=self.private_key)

  async def send_transaction(self, account, to, selector_name, calldata, nonce=None, max_fee=0):
    return await self.send_transactions(account, [(to, selector_name, calldata)], nonce, max_fee)

  async def send_transactions(self, account, calls, nonce=None, max_fee=0):
    if nonce is None:
      execution_info = await account.get_nonce().call()
      nonce, = execution_info.result

    calls_with_selector = [
      (call[0], get_selector_from_name(call[1]), call[2]) for call in calls]
    (call_array, calldata) = from_call_to_call_array(calls)

    message_hash = get_transaction_hash(account.contract_address, call_array, calldata, nonce, max_fee)
    sig_r, sig_s = self.sign(message_hash)

    return await account.__execute__(call_array, calldata, nonce).invoke(signature=[sig_r, sig_s])

# Custom Utils

def dict_to_tuple(data):
  return tuple(dict_to_tuple(d) if type(d) is dict else d for d in data.values())


def to_starknet_args(data):
  items = []
  values = data.values() if type(data) is dict else data
  for d in values:
    if type(d) is dict:
      items.extend([*to_starknet_args(d)])
    elif type(d) is tuple:
      items.extend([*to_starknet_args(d)])
    elif type(d) is list:
      items.append(len(d))
      items.extend([*to_starknet_args(tuple(d))])
    else:
      items.append(d)

  return tuple(items)


def update_card(card, **new):
  if 'serial_number' in new:
    card = update_dict(card, serial_number=new['serial_number'])
    del new['serial_number']

  return update_dict(card, model=update_dict(card['model'], **new))


def update_dict(dict, **new):
  return (lambda d: d.update(**new) or d)(dict.copy())


def get_contract(ctx, contract_name):
  contract = getattr(ctx, contract_name, None)
  if not contract:
    raise AttributeError(f"ctx.'{contract_name}' doesn't exists.")

  return (contract)


def get_declared_class(ctx, contract_class_name):
  contract_class = getattr(ctx, contract_class_name, None)
  if not contract_class:
    raise AttributeError(f"ctx.'{contract_class_name}' doesn't exists.")

  return (contract_class)


def get_account_address(ctx, account_name):
  if account_name == "null":
    return 0
  elif account_name == "dead":
    return 0xdead

  return (get_contract(ctx, account_name).contract_address)


def get_method(contract, method_name):
  method = getattr(contract, method_name, None)
  if not method:
    raise AttributeError(f"contract.'{method_name}' doesn't exists.")

  return (method)


def to_uint(a):
  """Takes in value, returns uint256-ish tuple."""
  return (a & ((1 << 128) - 1), a >> 128)


def from_uint(uint):
  """Takes in uint256-ish tuple, returns value."""
  return uint[0] + (uint[1] << 128)


def felts_to_ascii(felts):
  return reduce(lambda acc, felt: acc + bytearray.fromhex("{:x}".format(felt)).decode(), felts, "")


def felts_to_string(felts):
  return reduce(lambda acc, felt: acc + "{:x}".format(felt), felts, "")


def compute_card_id(card):
  return (
    card['model']['artist_name'][0],
    card['model']['artist_name'][1] + card['model']['scarcity'] * 2 ** 88 + card['model']['season'] * 2 ** 96 + card['serial_number'] * 2 ** 104
  )
