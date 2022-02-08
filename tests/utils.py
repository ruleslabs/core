from itertools import chain

def dict_to_tuple(data):
  return tuple(dict_to_tuple(d) if type(d) is dict else d for d in data.values())


def to_flat_tuple(data):
  items = []
  values = data.values() if type(data) is dict else data
  for d in values:
    if type(d) is dict:
      items.extend([*to_flat_tuple(d)])
    elif type(d) is tuple:
      items.extend([*to_flat_tuple(d)])
    else:
      items.append(d)

  return tuple(items)


def update_dict(dict, **new):
  return (lambda d: d.update(**new) or d)(dict.copy())


def get_contract(ctx, contract_name):
  contract = getattr(ctx, contract_name, None)
  if not contract:
    raise AttributeError(f"ctx.'{contract_name}' doesn't exists.")

  return (contract)


def get_method(contract, method_name):
  method = getattr(contract, method_name, None)
  if not method:
    raise AttributeError(f"contract.'{method_name}' doesn't exists.")

  return (method)
